import { Page, Locator, expect } from '@playwright/test'

export class PostsPage {
  readonly page: Page
  readonly postsTable: Locator
  readonly tableRows: Locator
  readonly pagination: Locator
  readonly visibilityDropdown: Locator
  readonly labelDropdown: Locator
  readonly deleteButton: Locator
  readonly confirmDelete: Locator
  readonly pageTitle: Locator
  readonly loadingSpinner: Locator

  constructor(page: Page) {
    this.page = page
    this.postsTable = page.locator('table, [class*="table"], .ant-table')
    this.tableRows = page.locator('tr, [class*="table-row"], .ant-table-row')
    this.pagination = page.locator('.ant-pagination, [class*="pagination"]')
    this.pageTitle = page.locator('h1:has-text("Posts"), h2:has-text("Posts")')
    this.loadingSpinner = page.locator('.ant-spin, [class*="loading"], [class*="spinner"]')
  }

  async goto() {
    await this.page.goto('/posts')
    await this.page.waitForLoadState('networkidle')
  }

  async expectPostsPageLoaded() {
    await expect(this.pageTitle.first()).toBeVisible({ timeout: 15000 })
    await expect(this.postsTable.first()).toBeVisible({ timeout: 10000 })
  }

  async getPostsCount(): Promise<number> {
    await this.loadingSpinner.waitFor({ state: 'hidden', timeout: 10000 }).catch(() => {})
    return await this.tableRows.count()
  }

  async expectPaginationVisible() {
    await expect(this.pagination.first()).toBeVisible({ timeout: 10000 })
  }

  async clickVisibilityDropdown(rowIndex: number) {
    const row = this.tableRows.nth(rowIndex)
    const dropdown = row.locator('[class*="visibility"], [class*="status-select"], .ant-select')
    await dropdown.first().click()
  }

  async selectVisibilityOption(option: string) {
    const optionLocator = this.page.locator(`.ant-select-dropdown [label="${option}"], .ant-select-item:has-text("${option}")`)
    await optionLocator.first().click()
  }

  async clickLabelDropdown(rowIndex: number) {
    const row = this.tableRows.nth(rowIndex)
    const dropdown = row.locator('[class*="label"], [class*="tag-select"], .ant-select')
    await dropdown.nth(1).click()
  }

  async selectLabelOption(option: string) {
    const optionLocator = this.page.locator(`.ant-select-dropdown:visible [label="${option}"], .ant-select-item:visible:has-text("${option}")`)
    await optionLocator.first().click()
  }

  async clickDelete(rowIndex: number) {
    const row = this.tableRows.nth(rowIndex)
    const deleteBtn = row.locator('button:has-text("Delete"), [class*="delete-btn"], [type="delete"]')
    await deleteBtn.first().click()
  }

  async confirmDeleteAction() {
    const confirmBtn = this.page.locator('.ant-popconfirm .ant-btn-primary:has-text("Delete"), .ant-modal .ant-btn-primary:has-text("Confirm"), button:has-text("Delete"):visible')
    await confirmBtn.first().click()
  }
}
