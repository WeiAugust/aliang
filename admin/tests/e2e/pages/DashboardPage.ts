import { Page, Locator, expect } from '@playwright/test'

export class DashboardPage {
  readonly page: Page
  readonly statCards: Locator
  readonly dailyActivitySection: Locator
  readonly platformHealthSection: Locator
  readonly welcomeText: Locator
  readonly logoutButton: Locator

  constructor(page: Page) {
    this.page = page
    this.statCards = page.locator('.ant-card, [class*="stat-card"], [class*="statCard"]')
    this.dailyActivitySection = page.locator('[class*="daily-activity"], [class*="activity-chart"], #daily-activity')
    this.platformHealthSection = page.locator('[class*="platform-health"], [class*="health-section"], #platform-health')
    this.welcomeText = page.locator('h1:has-text("Dashboard"), h1:has-text("Welcome"), [class*="welcome"]')
    this.logoutButton = page.locator('[class*="logout"], button:has-text("Logout"), [class*="user-menu"]')
  }

  async goto() {
    await this.page.goto('/dashboard')
    await this.page.waitForLoadState('networkidle')
  }

  async expectDashboardLoaded() {
    await expect(this.welcomeText.first()).toBeVisible({ timeout: 15000 })
  }

  async getStatCardCount(): Promise<number> {
    return await this.statCards.count()
  }

  async expectStatCards(count: number) {
    await expect(this.statCards).toHaveCount(count, { timeout: 10000 })
  }

  async expectDailyActivityVisible() {
    await expect(this.dailyActivitySection.first()).toBeVisible({ timeout: 10000 })
  }

  async expectPlatformHealthVisible() {
    await expect(this.platformHealthSection.first()).toBeVisible({ timeout: 10000 })
  }
}
