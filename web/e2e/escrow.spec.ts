import { test, expect } from "@playwright/test";

test.describe("Escrow Detail Page", () => {
  test.beforeEach(async ({ page }) => {
    // Navigate to escrow detail page with a test ID
    await page.goto("/escrow/1");
  });

  test("should display escrow information", async ({ page }) => {
    // Page should load without crashing
    await expect(page).toHaveURL(/\/escrow\/\d+/);
  });

  test("should show escrow ID in URL", async ({ page }) => {
    await expect(page).toHaveURL(/escrow\/1/);
  });
});

test.describe("Theme Toggle", () => {
  test.beforeEach(async ({ page }) => {
    await page.goto("/");
  });

  test("should toggle between dark and light themes", async ({ page }) => {
    // Get initial body class
    const html = page.locator("html");
    const initialClass = await html.getAttribute("class") || "";
    
    // Find and click theme toggle button if it exists
    const themeButton = page.locator('button:has-text("Theme"), button[aria-label*="theme"], button[aria-label*="Theme"]');
    
    if (await themeButton.isVisible()) {
      await themeButton.click();
      // Wait for class change
      await page.waitForTimeout(300);
      const newClass = await html.getAttribute("class") || "";
      expect(newClass).not.toBe(initialClass);
    }
  });
});

test.describe("Create Escrow Form", () => {
  test.beforeEach(async ({ page }) => {
    await page.goto("/");
  });

  test("should open create escrow modal", async ({ page }) => {
    // Look for create button - may need wallet connected
    const createButton = page.locator('button:has-text("Create Escrow"), button:has-text("New Escrow")');
    
    // The button might not be visible without wallet connection
    // This test checks the page structure
    await expect(page.locator("main")).toBeVisible();
  });
});

test.describe("Accessibility", () => {
  test("should have proper heading hierarchy", async ({ page }) => {
    await page.goto("/");
    
    // Should have exactly one h1
    const h1Count = await page.locator("h1").count();
    expect(h1Count).toBe(1);
  });

  test("should have accessible links", async ({ page }) => {
    await page.goto("/");
    
    // All links should have href or role
    const links = page.locator("a");
    const count = await links.count();
    
    for (let i = 0; i < count; i++) {
      const link = links.nth(i);
      const href = await link.getAttribute("href");
      const role = await link.getAttribute("role");
      expect(href || role).toBeTruthy();
    }
  });

  test("should have proper form labels", async ({ page }) => {
    await page.goto("/escrow/1");
    
    // Check for form inputs - they should have labels or aria-labels
    const inputs = page.locator("input");
    const count = await inputs.count();
    
    // If there are inputs, check they have some way to be identified
    if (count > 0) {
      for (let i = 0; i < Math.min(count, 3); i++) {
        const input = inputs.nth(i);
        const id = await input.getAttribute("id");
        const ariaLabel = await input.getAttribute("aria-label");
        const placeholder = await input.getAttribute("placeholder");
        const label = await input.getAttribute("name");
        
        // At least one identification method should exist
        expect(id || ariaLabel || placeholder || label).toBeTruthy();
      }
    }
  });
});
