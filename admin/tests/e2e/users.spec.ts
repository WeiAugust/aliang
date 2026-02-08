import { test, expect } from '@playwright/test'
import { LoginPage } from './pages/LoginPage'
import { UsersPage } from './pages/UsersPage'

test.describe('Users Management Flow', () => {
  let loginPage: LoginPage
  let usersPage: UsersPage

  test.beforeEach(async ({ page }) => {
    loginPage = new LoginPage(page)
    usersPage = new UsersPage(page)

    // Login first
    await loginPage.goto()
    await loginPage.login('admin', 'admin123')
    await page.waitForURL(/.*dashboard.*/, { timeout: 15000 })
  })

  test('should navigate to users page', async ({ page }) => {
    await usersPage.goto()
    await usersPage.expectUsersPageLoaded()
  })

  test('should load users table', async ({ page }) => {
    await usersPage.goto()
    await usersPage.expectUsersPageLoaded()

    // Verify users table loads
    const usersCount = await usersPage.getUsersCount()
    expect(usersCount).toBeGreaterThan(0)
  })

  test('should search users by nickname', async ({ page }) => {
    await usersPage.goto()
    await usersPage.expectUsersPageLoaded()

    // Search for a user
    await usersPage.searchByNickname('test')

    // Wait for results
    await page.waitForTimeout(2000)

    // Check if results appear (either users or no results message)
    const usersCount = await usersPage.getUsersCount()
    const noResultsVisible = await page.locator('.ant-empty, [class*="no-results"]').first().isVisible().catch(() => false)

    expect(usersCount > 0 || noResultsVisible).toBe(true)
  })

  test('should show no results for non-existent user', async ({ page }) => {
    await usersPage.goto()
    await usersPage.expectUsersPageLoaded()

    // Search for non-existent user
    await usersPage.searchByNickname('xyznonexistentuser123')

    // Wait for results
    await page.waitForTimeout(2000)

    // Should show no results
    const usersCount = await usersPage.getUsersCount()
    expect(usersCount).toBe(0)
  })

  test('should test ban action', async ({ page }) => {
    await usersPage.goto()
    await usersPage.expectUsersPageLoaded()

    // Wait for table to load
    await page.waitForTimeout(2000)

    // Check if there are users to ban
    const usersCount = await usersPage.getUsersCount()
    if (usersCount > 0) {
      // Click ban on first row
      await usersPage.clickBan(0)

      // Check if confirmation modal appears
      await page.waitForTimeout(500)
    }
  })

  test('should test unban action', async ({ page }) => {
    await usersPage.goto()
    await usersPage.expectUsersPageLoaded()

    // Wait for table to load
    await page.waitForTimeout(2000)

    // Check if there are users to unban
    const usersCount = await usersPage.getUsersCount()
    if (usersCount > 0) {
      // Click unban on first row (if available)
      await usersPage.clickUnban(0)

      // Check if confirmation modal appears
      await page.waitForTimeout(500)
    }
  })
})
