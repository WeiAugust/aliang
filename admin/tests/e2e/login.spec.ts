import { test, expect } from '@playwright/test'
import { LoginPage } from './pages/LoginPage'
import { DashboardPage } from './pages/DashboardPage'

test.describe('Admin Login Flow', () => {
  let loginPage: LoginPage
  let dashboardPage: DashboardPage

  test.beforeEach(async ({ page }) => {
    loginPage = new LoginPage(page)
    dashboardPage = new DashboardPage(page)
    // Clear auth state before each test
    await page.evaluate(() => {
      try {
        localStorage.clear()
      } catch (e) {
        // Ignore localStorage errors
      }
    })
  })

  test('should redirect to login page when accessing root without auth', async ({ page }) => {
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

    // Wait for navigation to dashboard (login form submits and navigates)
    await page.waitForURL(/.*dashboard.*/, { timeout: 30000 })

    // Verify dashboard loaded
    await dashboardPage.expectDashboardLoaded()
  })

  test('should show error for invalid credentials', async ({ page }) => {
    await loginPage.goto()
    await loginPage.expectLoginPage()

    // Try invalid login
    await loginPage.login('admin', 'wrongpassword')

    // Wait a bit for the error to appear
    await page.waitForTimeout(2000)

    // Should either show error or stay on login page
    const stillOnLogin = page.url().includes('login')
    const errorVisible = await loginPage.errorMessage.isVisible().catch(() => false)
    expect(stillOnLogin || errorVisible).toBe(true)
  })
})
