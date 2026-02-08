import { Page, Locator, expect } from '@playwright/test'

export class UsersPage {
  readonly page: Page
  readonly usersTable: Locator
  readonly tableRows: Locator
  readonly searchInput: Locator
  readonly searchButton: Locator
  readonly banButton: Locator
  readonly unbanButton: Locator
  readonly confirmBan: Locator
  readonly confirmUnban: Locator
  readonly pageTitle: Locator
  readonly loadingSpinner: Locator

  constructor(page: Page) {
    this.page = page
    this.usersTable = page.locator('table, [class*="table"], .ant-table')
    this.tableRows = page.locator('tr, [class*="table-row"], .ant-table-row')
    this.searchInput = page.locator('input[placeholder*="search"], input[placeholder*="nickname"], [class*="search"] input')
    this.searchButton = page.locator('button:has-text("Search"), [class*="search-btn"]')
    this.pageTitle = page.locator('h1:has-text("Users"), h2:has-text("Users")')
    this.loadingSpinner = page.locator('.ant-spin, [class*="loading"], [class*="spinner"]')
  }

  async goto() {
    await this.page.goto('/users')
    await this.page.waitForLoadState('networkidle')
  }

  async expectUsersPageLoaded() {
    await expect(this.pageTitle.first()).toBeVisible({ timeout: 15000 })
    await expect(this.usersTable.first()).toBeVisible({ timeout: 10000 })
  }

  async getUsersCount(): Promise<number> {
    await this.loadingSpinner.waitFor({ state: 'hidden', timeout: 10000 }).catch(() => {})
    return await this.tableRows.count()
  }

  async searchByNickname(nickname: string) {
    await this.searchInput.fill(nickname)
    await this.searchButton.first().click()
    await this.loadingSpinner.waitFor({ state: 'hidden', timeout: 10000 }).catch(() => {})
  }

  async clickBan(rowIndex: number) {
    const row = this.tableRows.nth(rowIndex)
    const banBtn = row.locator('button:has-text("Ban"), [class*="ban-btn"]')
    await banBtn.first().click()
  }

  async clickUnban(rowIndex: number) {
    const row = this.tableRows.nth(rowIndex)
    const unbanBtn = row.locator('button:has-text("Unban"), [class*="unban-btn"]')
    await unbanBtn.first().click()
  }

  async confirmBanAction() {
    const confirmBtn = this.page.locator('.ant-popconfirm .ant-btn-primary:has-text("Ban"), button:has-text("Ban"):visible')
    await confirmBtn.first().click()
  }

  async confirmUnbanAction() {
    const confirmBtn = this.page.locator('.ant-popconfirm .ant-btn-primary:has-text("Unban"), button:has-text("Unban"):visible')
    await confirmBtn.first().click()
  }

  async expectUserInResults(nickname: string) {
    const userRow = this.page.locator(`.ant-table-row:has-text("${nickname}")`)
    await expect(userRow.first()).toBeVisible({ timeout: 10000 })
  }

  async expectNoResults() {
    const noResults = this.page.locator('.ant-empty, [class*="no-results"], :has-text("No data"):visible')
    await expect(noResults.first()).toBeVisible({ timeout: 10000 })
  }
}
