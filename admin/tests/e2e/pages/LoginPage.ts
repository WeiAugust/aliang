import { Page, Locator, expect } from '@playwright/test'

export class LoginPage {
  readonly page: Page
  readonly usernameInput: Locator
  readonly passwordInput: Locator
  readonly submitButton: Locator
  readonly errorMessage: Locator
  readonly loginForm: Locator

  constructor(page: Page) {
    this.page = page
    this.usernameInput = page.locator('input[placeholder="Username"]')
    this.passwordInput = page.locator('input[placeholder="Password"]')
    this.submitButton = page.locator('button[type="submit"]')
    this.errorMessage = page.locator('.ant-message')
    this.loginForm = page.locator('.ant-card')
  }

  async goto() {
    await this.page.goto('/login')
    await this.page.waitForLoadState('networkidle')
  }

  async login(username: string, password: string) {
    await this.usernameInput.fill(username)
    await this.passwordInput.fill(password)
    await this.submitButton.click()
  }

  async expectLoginPage() {
    await expect(this.loginForm).toBeVisible({ timeout: 10000 })
  }

  async expectError(message: string) {
    await expect(this.errorMessage).toContainText(message)
  }
}
