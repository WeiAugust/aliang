import { test, expect } from '@playwright/test'
import { LoginPage } from './pages/LoginPage'
import { DashboardPage } from './pages/DashboardPage'

test.describe('Dashboard Flow', () => {
  let loginPage: LoginPage
  let dashboardPage: DashboardPage

  test.beforeEach(async ({ page }) => {
    loginPage = new LoginPage(page)
    dashboardPage = new DashboardPage(page)

    // Clear auth state and login first
    await page.evaluate(() => {
      try {
        localStorage.clear()
      } catch (e) {
        // Ignore localStorage errors
      }
    })
    await loginPage.goto()
    await loginPage.expectLoginPage()
    await loginPage.login('admin', 'admin123')
    await page.waitForURL(/.*dashboard.*/, { timeout: 30000 })
  })

  test('should load dashboard stats cards', async ({ page }) => {
    await dashboardPage.expectDashboardLoaded()

    // Verify 4 stat cards render
    const statCount = await dashboardPage.getStatCardCount()
    expect(statCount).toBeGreaterThanOrEqual(4)
  })

  test('should show daily activity section', async ({ page }) => {
    await dashboardPage.expectDashboardLoaded()

    // Verify daily activity section is visible
    await dashboardPage.expectDailyActivityVisible()
  })

  test('should show platform health section', async ({ page }) => {
    await dashboardPage.expectDashboardLoaded()

    // Verify platform health section is visible
    await dashboardPage.expectPlatformHealthVisible()
  })

  test('should display all dashboard components', async ({ page }) => {
    await dashboardPage.expectDashboardLoaded()

    // Verify all expected components
    await dashboardPage.expectStatCards(4)
    await dashboardPage.expectDailyActivityVisible()
    await dashboardPage.expectPlatformHealthVisible()
  })
})
