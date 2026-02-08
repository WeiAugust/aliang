import { test, expect } from '@playwright/test'
import { LoginPage } from './pages/LoginPage'
import { DashboardPage } from './pages/DashboardPage'

test.describe('Admin Login Flow', () => {
  let loginPage: LoginPage
  let dashboardPage: DashboardPage

  test.beforeEach(async ({ page }) => {
    loginPage = new LoginPage(page)
    dashboardPage = new DashboardPage(page)
  })

  test('should redirect to login page when accessing root', async ({ page }) => {
    await page.goto('/')
    await page.waitForLoadState('networkidle')

    // Should redirect to login page
    await expect(page).toHaveURL(/.*login.*/)
  })

  test('should login successfully with admin/admin123', async ({ page }) => {
    await loginPage.goto()
    await loginPage.expectLoginPage()

    // Perform login
    await loginPage.login('admin', 'admin123')

    // Wait for navigation to dashboard
    await page.waitForURL(/.*dashboard.*/, { timeout: 15000 })

    // Verify dashboard loaded
    await dashboardPage.expectDashboardLoaded()
  })

  test('should show error for invalid credentials', async ({ page }) => {
    await loginPage.goto()
    await loginPage.expectLoginPage()

    // Try invalid login
    await loginPage.login('admin', 'wrongpassword')

    // Should show error message
    await page.waitForTimeout(1000)
    const errorVisible = await loginPage.errorMessage.isVisible()
    expect(errorVisible || page.url.includes('login')).toBe(true)
  })
})
