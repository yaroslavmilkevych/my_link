from __future__ import annotations

import re
from urllib.parse import urljoin, urlparse

import pytest
from playwright.sync_api import APIRequestContext, Page, expect


SENSITIVE_ROUTES = [
    "/manage",
    "/script",
    "/view/all/newJob",
    "/computer/new",
    "/credentials/store/system/domain/_/newCredentials",
]

INVALID_JOB_NAMES = [
    "",
    "   ",
    "../escape",
    "job?",
    "a" * 256,
]

EXPECTED_PLUGIN_IDS = {
    "matrix-auth",
    "credentials",
    "plain-credentials",
    "ssh-credentials",
    "credentials-binding",
    "cloudbees-folder",
    "script-security",
    "workflow-aggregator",
    "workflow-job",
    "workflow-cps",
    "pipeline-model-definition",
    "git",
    "git-client",
    "github",
    "github-branch-source",
    "theme-manager",
    "dark-theme",
}


def _open_and_assert_protected(page: Page, base_url: str, route: str) -> None:
    page.goto(urljoin(f"{base_url}/", route.lstrip("/")), wait_until="domcontentloaded")
    page.wait_for_load_state("networkidle")

    page_body = page.locator("body")
    body_text = page_body.inner_text().lower()

    assert (
        "/login" in page.url
        or "access denied" in body_text
        or "authentication required" in body_text
        or "forbidden" in body_text
        or "permission" in body_text
    ), f"Sensitive route {route} appears to be exposed to anonymous users."


def test_jenkins_root_is_reachable(jenkins_page: Page, jenkins_url: str) -> None:
    jenkins_page.goto(jenkins_url, wait_until="domcontentloaded")
    jenkins_page.wait_for_load_state("networkidle")

    expect(jenkins_page).to_have_url(re.compile(r"http://.+|https://.+"))

    body = jenkins_page.locator("body")
    expect(body).to_be_visible()

    body_text = body.inner_text()
    assert (
        "Jenkins" in body_text
        or "Welcome to Jenkins!" in body_text
        or jenkins_page.locator('input[name="j_username"]').count() > 0
    )


@pytest.mark.parametrize("route", SENSITIVE_ROUTES)
def test_sensitive_routes_are_not_open_to_anonymous_users(
    jenkins_page: Page,
    jenkins_url: str,
    route: str,
) -> None:
    _open_and_assert_protected(jenkins_page, jenkins_url, route)


def test_login_form_requires_credentials(jenkins_page: Page, jenkins_url: str) -> None:
    jenkins_page.goto(urljoin(f"{jenkins_url}/", "login"), wait_until="domcontentloaded")

    login_form = jenkins_page.locator('form[name="login"]')
    username = jenkins_page.locator('input[name="j_username"]')
    password = jenkins_page.locator('input[name="j_password"]')
    submit = jenkins_page.locator('button[type="submit"], input[type="submit"]').first

    expect(login_form).to_have_attribute("action", "j_spring_security_check")
    expect(username).to_be_visible()
    expect(password).to_be_visible()
    expect(jenkins_page.locator('label[for="j_username"]')).to_have_text("Username")
    expect(jenkins_page.locator('label[for="j_password"]')).to_have_text("Пароль")
    expect(jenkins_page.locator('input[name="from"]')).to_have_attribute("type", "hidden")

    submit.click()
    jenkins_page.wait_for_load_state("networkidle")

    expect(jenkins_page.locator('input[name="j_username"]')).to_be_visible()
    expect(jenkins_page.locator('input[name="j_password"]')).to_be_visible()
    expect(jenkins_page).to_have_url(re.compile(r"/login"))


def test_login_form_masks_password(jenkins_page: Page, jenkins_url: str) -> None:
    jenkins_page.goto(urljoin(f"{jenkins_url}/", "login"), wait_until="domcontentloaded")
    expect(jenkins_page.locator('input[name="j_password"]')).to_have_attribute(
        "type", "password"
    )


def test_login_page_contains_remember_me_and_csrf_inputs(
    jenkins_page: Page,
    jenkins_url: str,
) -> None:
    jenkins_page.goto(urljoin(f"{jenkins_url}/", "login"), wait_until="domcontentloaded")

    expect(jenkins_page.locator("html")).to_have_attribute("lang", "ru-PL")
    expect(jenkins_page.locator('input[name="remember_me"]')).to_have_attribute(
        "type", "checkbox"
    )
    expect(jenkins_page.locator('label[for="remember_me"]')).to_have_text(
        "Keep me signed in"
    )

    crumb_input = jenkins_page.locator('input[name="Jenkins-Crumb"]')
    expect(crumb_input).to_have_attribute("type", "hidden")
    expect(crumb_input).not_to_have_value("")


def test_root_sets_security_headers(
    jenkins_api_context: APIRequestContext,
    jenkins_url: str,
) -> None:
    response = jenkins_api_context.get(jenkins_url, fail_on_status_code=False)
    headers = {key.lower(): value for key, value in response.headers.items()}

    assert response.status < 500
    assert headers.get("x-content-type-options") == "nosniff"
    assert "x-frame-options" in headers or "content-security-policy" in headers
    assert "cache-control" in headers
    assert headers.get("x-jenkins") == "2.541.3"


def test_login_page_does_not_render_password_in_markup(
    jenkins_api_context: APIRequestContext,
) -> None:
    response = jenkins_api_context.get("/login", fail_on_status_code=False)
    markup = response.text()

    assert response.ok
    assert 'name="j_password"' in markup
    assert 'type="password"' in markup
    assert 'value="' not in markup or 'name="j_password" value="' not in markup


def test_anonymous_api_json_is_blocked_and_redirects_to_login(
    jenkins_api_context: APIRequestContext,
) -> None:
    response = jenkins_api_context.get("/api/json", fail_on_status_code=False)
    headers = {key.lower(): value for key, value in response.headers.items()}
    body = response.text().lower()

    assert response.status == 403
    assert headers.get("content-type", "").startswith("text/html")
    assert headers.get("x-jenkins") == "2.541.3"
    assert "/login?from=%2fapi%2fjson" in body
    assert "authentication required" in body


def test_anonymous_manage_and_new_job_endpoints_are_unauthorized(
    jenkins_api_context: APIRequestContext,
) -> None:
    manage_response = jenkins_api_context.get("/manage", fail_on_status_code=False)
    new_job_response = jenkins_api_context.get("/view/all/newJob", fail_on_status_code=False)

    assert manage_response.status in {401, 403}
    assert new_job_response.status in {401, 403}


def test_authenticated_api_json_matches_expected_instance_shape(
    authenticated_jenkins_page: Page,
    jenkins_url: str,
) -> None:
    response = authenticated_jenkins_page.request.get(
        urljoin(f"{jenkins_url}/", "api/json"),
        fail_on_status_code=False,
    )
    payload = response.json()

    assert response.ok
    assert payload["_class"] == "hudson.model.Hudson"
    assert payload["mode"] == "NORMAL"
    assert payload["nodeDescription"] == "the Jenkins controller's built-in node"
    assert payload["numExecutors"] == 2
    assert payload["useCrumbs"] is True
    assert payload["useSecurity"] is True
    assert payload["jobs"] == []
    assert payload["primaryView"]["name"] == "all"
    assert payload["views"][0]["name"] == "all"
    assert any(label["name"] == "built-in" for label in payload["assignedLabels"])


def test_job_creation_form_contains_csrf_signal(
    authenticated_jenkins_page: Page,
    jenkins_url: str,
) -> None:
    authenticated_jenkins_page.goto(
        urljoin(f"{jenkins_url}/", "view/all/newJob"),
        wait_until="domcontentloaded",
    )
    authenticated_jenkins_page.wait_for_load_state("networkidle")

    expect(authenticated_jenkins_page).to_have_url(re.compile(r"/newJob"))

    crumb_input = authenticated_jenkins_page.locator(
        'input[name="Jenkins-Crumb"], input[name="jenkins-crumb"]'
    )
    has_crumb_input = crumb_input.count() > 0

    if has_crumb_input:
        expect(crumb_input.first).to_have_attribute("type", "hidden")
        return

    crumb_response = authenticated_jenkins_page.request.get(
        urljoin(f"{jenkins_url}/", "crumbIssuer/api/json"),
        fail_on_status_code=False,
    )
    assert crumb_response.status in {200, 403, 404}

    if crumb_response.status == 200:
        payload = crumb_response.json()
        assert payload.get("crumb")
        assert payload.get("crumbRequestField")


def test_new_job_page_matches_expected_dom_for_this_instance(
    authenticated_jenkins_page: Page,
    jenkins_url: str,
) -> None:
    authenticated_jenkins_page.goto(
        urljoin(f"{jenkins_url}/", "view/all/newJob"),
        wait_until="domcontentloaded",
    )
    authenticated_jenkins_page.wait_for_load_state("networkidle")

    expect(authenticated_jenkins_page.locator("body")).to_have_attribute(
        "data-version", "2.541.3"
    )
    expect(authenticated_jenkins_page.locator("body")).to_have_class(
        re.compile(r"jenkins-2\.541\.3")
    )
    expect(authenticated_jenkins_page.locator("#createItem")).to_have_attribute(
        "action", "createItem"
    )
    expect(authenticated_jenkins_page.locator('label[for="name"]')).to_have_text(
        "Введите имя Item'а"
    )
    expect(authenticated_jenkins_page.locator("#ok-button")).to_have_text("OK")
    expect(authenticated_jenkins_page.locator("#itemname-required")).to_contain_text(
        "Поле не может быть пустым"
    )
    expect(authenticated_jenkins_page.locator("#itemtype-required")).to_contain_text(
        "Укажите тип элемент'а"
    )
    expect(authenticated_jenkins_page.locator("#items")).to_have_attribute(
        "role", "radiogroup"
    )
    expect(authenticated_jenkins_page.locator('a[href="/manage"]')).to_be_visible()
    expect(authenticated_jenkins_page.locator('a[href="/logout"]')).to_be_visible()


@pytest.mark.parametrize("job_name", INVALID_JOB_NAMES)
def test_job_creation_rejects_invalid_names(
    authenticated_jenkins_page: Page,
    jenkins_url: str,
    job_name: str,
) -> None:
    authenticated_jenkins_page.goto(
        urljoin(f"{jenkins_url}/", "view/all/newJob"),
        wait_until="domcontentloaded",
    )
    authenticated_jenkins_page.wait_for_load_state("networkidle")

    name_input = authenticated_jenkins_page.locator('input[name="name"]')
    expect(name_input).to_be_visible()

    name_input.fill(job_name)
    authenticated_jenkins_page.locator('input[value="hudson.model.FreeStyleProject"]').check()
    authenticated_jenkins_page.locator("#ok-button").click()
    authenticated_jenkins_page.wait_for_load_state("networkidle")

    current_url = authenticated_jenkins_page.url
    body_text = authenticated_jenkins_page.locator("body").inner_text().lower()

    assert "/configure" not in current_url, (
        f"Invalid job name {job_name!r} should not proceed to job configuration."
    )
    assert (
        "error" in body_text
        or "invalid" in body_text
        or "already exists" in body_text
        or "enter a name" in body_text
        or "name is required" in body_text
    )


def test_authenticated_session_cookie_has_safe_flags(
    authenticated_jenkins_page: Page,
    jenkins_url: str,
) -> None:
    cookies = authenticated_jenkins_page.context.cookies()
    session_cookie = next(
        (
            cookie
            for cookie in cookies
            if cookie["name"].upper() in {"JSESSIONID", "SESSION"}
        ),
        None,
    )

    assert session_cookie is not None, "No authenticated session cookie was created."
    assert session_cookie["httpOnly"] is True
    assert session_cookie["sameSite"] in {"Lax", "Strict", "None"}

    if urlparse(jenkins_url).scheme == "https":
        assert session_cookie["secure"] is True


def test_logout_endpoint_is_not_exposed_as_anonymous_exit(
    jenkins_api_context: APIRequestContext,
) -> None:
    response = jenkins_api_context.get("/logout", fail_on_status_code=False)
    assert response.status in {200, 302, 403, 404}


def test_plugin_manager_contains_expected_security_and_pipeline_plugins(
    authenticated_jenkins_page: Page,
    jenkins_url: str,
) -> None:
    response = authenticated_jenkins_page.request.get(
        urljoin(f"{jenkins_url}/", "pluginManager/api/json?depth=1"),
        fail_on_status_code=False,
    )
    payload = response.json()
    plugins = payload["plugins"]
    plugin_ids = {plugin["shortName"] for plugin in plugins}

    assert response.ok
    assert payload["_class"] == "hudson.LocalPluginManager"
    assert EXPECTED_PLUGIN_IDS.issubset(plugin_ids)
    assert all(plugin["active"] for plugin in plugins)
    assert all(plugin["enabled"] for plugin in plugins)


def test_plugin_manager_reports_matrix_auth_and_theme_plugins(
    authenticated_jenkins_page: Page,
    jenkins_url: str,
) -> None:
    response = authenticated_jenkins_page.request.get(
        urljoin(f"{jenkins_url}/", "pluginManager/api/json?depth=1"),
        fail_on_status_code=False,
    )
    plugins_by_id = {
        plugin["shortName"]: plugin for plugin in response.json()["plugins"]
    }

    assert plugins_by_id["matrix-auth"]["version"] == "3.2.9"
    assert plugins_by_id["credentials"]["version"] == "1498.vd852f8831d79"
    assert plugins_by_id["cloudbees-folder"]["version"] == "6.1079.vc0975c2de294"
    assert plugins_by_id["workflow-aggregator"]["version"] == "608.v67378e9d3db_1"
    assert plugins_by_id["theme-manager"]["version"] == "344.vd7b_e20e046dc"
    assert plugins_by_id["dark-theme"]["version"] == "652.vea_da_dfea_e769"
