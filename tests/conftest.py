from __future__ import annotations

import contextlib
import os
import socket
import threading
from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import urljoin

import pytest
from playwright.sync_api import (
    APIRequestContext,
    Browser,
    Page,
    Playwright,
    sync_playwright,
)


PROJECT_ROOT = Path(__file__).resolve().parents[1]


def _get_free_port() -> int:
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:
        sock.bind(("127.0.0.1", 0))
        return int(sock.getsockname()[1])


def _env_flag(name: str, default: bool) -> bool:
    value = os.getenv(name)
    if value is None:
        return default
    return value.strip().lower() in {"1", "true", "yes", "on"}


def pytest_addoption(parser: pytest.Parser) -> None:
    parser.addoption(
        "--headed",
        action="store_true",
        default=False,
        help="Run Playwright with a visible browser window.",
    )
    parser.addoption(
        "--slowmo",
        action="store",
        default=None,
        help="Delay Playwright actions by the given milliseconds.",
    )
    parser.addoption(
        "--pause-before-close",
        action="store_true",
        default=False,
        help="Pause briefly before closing each browser context so the result stays visible.",
    )


@pytest.fixture(scope="session")
def server_url() -> str:
    try:
        port = _get_free_port()
    except PermissionError:
        yield PROJECT_ROOT.joinpath("index.html").resolve().as_uri()
        return

    handler = partial(SimpleHTTPRequestHandler, directory=str(PROJECT_ROOT))
    server = ThreadingHTTPServer(("127.0.0.1", port), handler)
    thread = threading.Thread(target=server.serve_forever, daemon=True)
    thread.start()

    try:
        yield f"http://127.0.0.1:{port}"
    finally:
        server.shutdown()
        server.server_close()
        thread.join(timeout=5)


@pytest.fixture(scope="session")
def playwright_instance() -> Playwright:
    with sync_playwright() as playwright:
        yield playwright


@pytest.fixture(scope="session")
def browser(playwright_instance: Playwright, pytestconfig: pytest.Config) -> Browser:
    headed = pytestconfig.getoption("--headed") or _env_flag("PLAYWRIGHT_HEADED", False)
    slow_mo_value = pytestconfig.getoption("--slowmo") or os.getenv("PLAYWRIGHT_SLOWMO", "0")

    try:
        slow_mo = int(slow_mo_value)
    except ValueError:
        slow_mo = 0

    try:
        browser = playwright_instance.chromium.launch(
            headless=not headed,
            slow_mo=slow_mo,
        )
    except Exception as exc:
        pytest.skip(f"Playwright browser could not be launched in this environment: {exc}")
    yield browser
    browser.close()


@pytest.fixture()
def pause_before_close(pytestconfig: pytest.Config) -> bool:
    return pytestconfig.getoption("--pause-before-close") or _env_flag(
        "PLAYWRIGHT_PAUSE_BEFORE_CLOSE",
        False,
    )


@pytest.fixture()
def page(browser: Browser, pause_before_close: bool) -> Page:
    context = browser.new_context(viewport={"width": 1440, "height": 1200})
    current_page = context.new_page()

    try:
        yield current_page
    finally:
        if pause_before_close:
            with contextlib.suppress(Exception):
                current_page.wait_for_timeout(1500)
        with contextlib.suppress(Exception):
            context.close()


@pytest.fixture(scope="session")
def jenkins_url() -> str:
    return os.getenv("JENKINS_URL", "http://localhost:8080").rstrip("/")


@pytest.fixture(scope="session")
def jenkins_username() -> str | None:
    return os.getenv("JENKINS_USERNAME")


@pytest.fixture(scope="session")
def jenkins_password() -> str | None:
    return os.getenv("JENKINS_PASSWORD")


@pytest.fixture(scope="session")
def jenkins_available(playwright_instance: Playwright, jenkins_url: str) -> bool:
    request_context = playwright_instance.request.new_context(ignore_https_errors=True)
    try:
        response = request_context.get(jenkins_url, fail_on_status_code=False)
        return response.status < 500
    except Exception:
        return False
    finally:
        request_context.dispose()


@pytest.fixture(scope="session")
def require_jenkins(jenkins_available: bool, jenkins_url: str) -> None:
    if not jenkins_available:
        pytest.skip(
            f"Jenkins is unavailable at {jenkins_url}. "
            "Set JENKINS_URL to a reachable instance before running these tests."
        )


@pytest.fixture(scope="session")
def require_jenkins_credentials(
    require_jenkins: None,
    jenkins_username: str | None,
    jenkins_password: str | None,
) -> tuple[str, str]:
    if not jenkins_username or not jenkins_password:
        pytest.skip(
            "Authenticated Jenkins checks require JENKINS_USERNAME and JENKINS_PASSWORD."
        )
    return jenkins_username, jenkins_password


@pytest.fixture()
def jenkins_page(
    browser: Browser,
    require_jenkins: None,
    pause_before_close: bool,
) -> Page:
    context = browser.new_context(
        viewport={"width": 1440, "height": 1200},
        ignore_https_errors=True,
    )
    current_page = context.new_page()

    try:
        yield current_page
    finally:
        if pause_before_close:
            with contextlib.suppress(Exception):
                current_page.wait_for_timeout(1500)
        with contextlib.suppress(Exception):
            context.close()


@pytest.fixture()
def authenticated_jenkins_page(
    jenkins_page: Page,
    jenkins_url: str,
    require_jenkins_credentials: tuple[str, str],
) -> Page:
    username, password = require_jenkins_credentials

    jenkins_page.goto(urljoin(f"{jenkins_url}/", "login"), wait_until="domcontentloaded")
    jenkins_page.locator('input[name="j_username"]').fill(username)
    jenkins_page.locator('input[name="j_password"]').fill(password)
    jenkins_page.locator('button[type="submit"], input[type="submit"]').first.click()
    jenkins_page.wait_for_load_state("networkidle")

    assert "/login" not in jenkins_page.url, "Jenkins login did not complete successfully."
    return jenkins_page


@pytest.fixture()
def jenkins_api_context(
    playwright_instance: Playwright,
    require_jenkins: None,
    jenkins_url: str,
) -> APIRequestContext:
    context = playwright_instance.request.new_context(
        base_url=jenkins_url,
        ignore_https_errors=True,
    )

    try:
        yield context
    finally:
        context.dispose()
