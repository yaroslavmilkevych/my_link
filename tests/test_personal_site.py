from __future__ import annotations

import re

from playwright.sync_api import Browser, expect


def test_homepage_renders_polish_learning_app(page, server_url: str) -> None:
    page.goto(server_url, wait_until="load")

    expect(page).to_have_title(re.compile("Polly Word"))
    expect(page.locator("h1")).to_contain_text("Польский")
    expect(page.locator("#auth-panel")).to_be_visible()
    expect(page.locator("#auth-form")).to_be_visible()
    expect(page.locator("#register-button")).to_have_text("Зарегистрироваться")


def test_register_opens_dashboard_and_word_sections(page, server_url: str) -> None:
    page.goto(server_url, wait_until="load")

    page.locator("#email-input").fill("learner@example.com")
    page.locator("#password-input").fill("secret1")
    page.locator("#register-button").click()

    expect(page.locator("#dashboard")).to_be_visible()
    expect(page.locator("#bottom-nav")).to_be_visible()
    expect(page.locator("#word-list .word-card")).to_have_count(12)
    expect(page.locator("#new-count")).to_have_text("12")


def test_sticker_archives_word_after_marking_known(page, server_url: str) -> None:
    page.goto(server_url, wait_until="load")

    page.locator("#email-input").fill("archive@example.com")
    page.locator("#password-input").fill("secret1")
    page.locator("#register-button").click()

    page.get_by_role("button", name="Игра").click()
    first_card = page.locator("#sticker-grid .sticker-card").first
    first_card.locator("[data-flip-word]").first.click()
    first_card.get_by_role("button", name="ЗНАЮ").click()

    page.get_by_role("button", name="Архив").click()
    expect(page.locator("#archive-word-list .archive-item")).to_have_count(1)
    expect(page.locator("#archived-count")).to_have_text("1")


def test_chat_mode_returns_training_feedback(page, server_url: str) -> None:
    page.goto(server_url, wait_until="load")

    page.locator("#email-input").fill("chat@example.com")
    page.locator("#password-input").fill("secret1")
    page.locator("#register-button").click()

    page.get_by_role("button", name="ИИ").click()
    page.locator("#chat-input").fill("ja chce kawa")
    page.locator("#chat-form button[type='submit']").click()

    expect(page.locator("#chat-log .chat-bubble")).to_have_count(2)
    expect(page.locator("#chat-log")).to_contain_text("Рекомендуемый вариант")
    expect(page.locator("#chat-log")).to_contain_text("Chcę kawę")


def test_mobile_layout_keeps_bottom_navigation_available(
    browser: Browser, server_url: str
) -> None:
    context = browser.new_context(
        viewport={"width": 390, "height": 844},
        is_mobile=True,
        has_touch=True,
    )
    page = context.new_page()

    try:
        page.goto(server_url, wait_until="load")
        page.locator("#email-input").fill("mobile@example.com")
        page.locator("#password-input").fill("secret1")
        page.locator("#register-button").click()

        expect(page.locator("#bottom-nav")).to_be_visible()
        expect(page.locator("#bottom-nav .bottom-nav__item")).to_have_count(4)
        expect(page.locator("#word-list .word-card").first).to_be_visible()
    finally:
        context.close()
