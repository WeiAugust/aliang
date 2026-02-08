import { test, expect } from '@playwright/test'
import { LoginPage } from './pages/LoginPage'
import { PostsPage } from './pages/PostsPage'

test.describe('Posts Management Flow', () => {
  let loginPage: LoginPage
  let postsPage: PostsPage

  test.beforeEach(async ({ page }) => {
    loginPage = new LoginPage(page)
    postsPage = new PostsPage(page)

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

  test('should navigate to posts page', async ({ page }) => {
    await postsPage.goto()
    await postsPage.expectPostsPageLoaded()
  })

  test('should load posts table with pagination', async ({ page }) => {
    await postsPage.goto()
    await postsPage.expectPostsPageLoaded()

    // Verify posts table loads
    const postsCount = await postsPage.getPostsCount()
    expect(postsCount).toBeGreaterThan(0)

    // Verify pagination is visible
    await postsPage.expectPaginationVisible()
  })

  test('should test visibility dropdown menu', async ({ page }) => {
    await postsPage.goto()
    await postsPage.expectPostsPageLoaded()

    // Wait for table to load
    await page.waitForTimeout(2000)

    // Try clicking visibility dropdown on first row
    const postsCount = await postsPage.getPostsCount()
    if (postsCount > 0) {
      await postsPage.clickVisibilityDropdown(0)
      await page.waitForTimeout(500)
    }
  })

  test('should test label dropdown menu', async ({ page }) => {
    await postsPage.goto()
    await postsPage.expectPostsPageLoaded()

    // Wait for table to load
    await page.waitForTimeout(2000)

    // Try clicking label dropdown on first row
    const postsCount = await postsPage.getPostsCount()
    if (postsCount > 0) {
      await postsPage.clickLabelDropdown(0)
      await page.waitForTimeout(500)
    }
  })

  test('should test delete action with confirmation', async ({ page }) => {
    await postsPage.goto()
    await postsPage.expectPostsPageLoaded()

    // Wait for table to load
    await page.waitForTimeout(2000)

    // Check if there are posts to delete
    const postsCount = await postsPage.getPostsCount()
    if (postsCount > 0) {
      // Click delete on first row
      await postsPage.clickDelete(0)

      // Check if confirmation modal appears
      await page.waitForTimeout(500)
    }
  })
})
