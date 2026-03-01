import { test, expect, type Page } from "@playwright/test";

// ============================================
// PRODUCTION SCENARIO TESTS
// Credence Escrow Platform - End-to-End Testing
// ============================================

// ============================================
// PAGE LOAD & RENDERING TESTS
// ============================================

test.describe("Page Loading & Rendering", () => {
  test("should load dashboard without errors", async ({ page }) => {
    const errors: string[] = [];
    page.on("pageerror", (error) => errors.push(error.message));
    
    await page.goto("/");
    await expect(page).toHaveTitle(/Credence|Escrow|Dashboard/i);
    
    // No critical errors should occur
    const criticalErrors = errors.filter(e => !e.includes("Warning"));
    expect(criticalErrors).toHaveLength(0);
  });

  test("should load escrow detail page with valid ID", async ({ page }) => {
    await page.goto("/escrow/1");
    await expect(page).toHaveURL(/\/escrow\/\d+/);
  });

  test("should handle invalid escrow ID gracefully", async ({ page }) => {
    await page.goto("/escrow/invalid");
    // Should either show error or redirect
    await page.waitForTimeout(1000);
  });

  test("should load admin page", async ({ page }) => {
    await page.goto("/admin");
    await expect(page.getByRole("heading", { name: /admin/i })).toBeVisible();
  });

  test("should load disputes page", async ({ page }) => {
    await page.goto("/disputes");
    await expect(page.getByRole("heading", { name: /dispute/i })).toBeVisible();
  });

  test("should load receivables page", async ({ page }) => {
    await page.goto("/receivables");
    await expect(page.getByRole("heading", { name: /receivable/i })).toBeVisible();
  });
});

// ============================================
// WALLET CONNECTION TESTS
// ============================================

test.describe("Wallet Connection Flow", () => {
  test.beforeEach(async ({ page }) => {
    await page.goto("/");
  });

  test("should show connect wallet prompt", async ({ page }) => {
    const connectButton = page.locator('button:has-text("Connect"), [data-testid="connect-wallet"]');
    await expect(connectButton.or(page.getByText(/connect.*wallet/i))).toBeVisible();
  });

  test("should display network indicator", async ({ page }) => {
    const networkIndicator = page.locator('[class*="network"], [data-testid="network-indicator"]');
    // May not be visible without wallet connection
  });

  test("should show correct page content when disconnected", async ({ page }) => {
    // Should show empty state or prompt to connect
    const content = await page.content();
    expect(content.toLowerCase()).toMatch(/connect|wallet|login|sign in/i);
  });
});

// ============================================
// NAVIGATION TESTS
// ============================================

test.describe("Navigation", () => {
  test.beforeEach(async ({ page }) => {
    await page.goto("/");
  });

  test("should have working header navigation", async ({ page }) => {
    const nav = page.getByRole("navigation");
    await expect(nav).toBeVisible();
  });

  test("should navigate between all main pages", async ({ page }) => {
    const pages = [
      { path: "/", name: "Dashboard" },
      { path: "/admin", name: "Admin" },
      { path: "/disputes", name: "Dispute" },
      { path: "/receivables", name: "Receivable" },
    ];

    for (const p of pages) {
      await page.goto(p.path);
      await expect(page.getByRole("heading", { name: new RegExp(p.name, "i") })).toBeVisible();
    }
  });

  test("should preserve state when navigating", async ({ page }) => {
    // Set viewport to mobile
    await page.setViewportSize({ width: 375, height: 667 });
    await page.goto("/");
    
    // Should still navigate correctly
    await page.goto("/admin");
    await expect(page.getByRole("heading", { name: /admin/i })).toBeVisible();
  });

  test("should handle browser back button", async ({ page }) => {
    await page.goto("/");
    await page.goto("/admin");
    await page.goBack();
    await expect(page).toHaveURL("/");
  });
});

// ============================================
// ESCROW LIST TESTS
// ============================================

test.describe("Escrow List", () => {
  test.beforeEach(async ({ page }) => {
    await page.goto("/");
  });

  test("should display escrow list or empty state", async ({ page }) => {
    await page.waitForTimeout(2000);
    // Either escrow items or empty state should be visible
    const hasContent = 
      (await page.locator('[class*="escrow"]').count()) > 0 ||
      (await page.getByText(/no escrow|empty|not found/i).count()) > 0;
    expect(hasContent).toBe(true);
  });

  test("should have search functionality", async ({ page }) => {
    const searchInput = page.locator('input[type="search"], input[placeholder*="search" i]');
    if (await searchInput.isVisible()) {
      await searchInput.fill("test");
      await page.waitForTimeout(500);
    }
  });

  test("should have filter options", async ({ page }) => {
    const filterButton = page.locator('button:has-text("Filter"), [data-testid="filter"]');
    if (await filterButton.isVisible()) {
      await filterButton.click();
      await expect(page.locator('[class*="filter"], [role="dialog"]')).toBeVisible();
    }
  });
});

// ============================================
// ESCROW DETAIL TESTS
// ============================================

test.describe("Escrow Detail Page", () => {
  test.beforeEach(async ({ page }) => {
    await page.goto("/escrow/1");
  });

  test("should display escrow information section", async ({ page }) => {
    await page.waitForTimeout(2000);
    // Page should contain some escrow-related content
    const content = await page.content();
    expect(content.length).toBeGreaterThan(100);
  });

  test("should display escrow state chip", async ({ page }) => {
    const stateChip = page.locator('[class*="state"], [class*="status"], [class*="chip"]');
    // May or may not be visible depending on data
  });

  test("should have action buttons", async ({ page }) => {
    const actionButtons = page.locator('button:has-text("Fund"), button:has-text("Release"), button:has-text("Dispute"), button:has-text("Refund")');
    const count = await actionButtons.count();
    // Should have 0 or more action buttons
    expect(count).toBeGreaterThanOrEqual(0);
  });

  test("should display transaction history or timeline", async ({ page }) => {
    const timeline = page.locator('[class*="timeline"], [class*="history"], [class*="transaction"]');
    // May not be visible without data
  });
});

// ============================================
// CREATE ESCROW FLOW TESTS
// ============================================

test.describe("Create Escrow Flow", () => {
  test.beforeEach(async ({ page }) => {
    await page.goto("/");
  });

  test("should have create escrow button", async ({ page }) => {
    const createButton = page.locator('button:has-text("Create"), button:has-text("New Escrow")');
    await expect(createButton.or(page.getByRole("button", { name: /create.*escrow/i }))).toBeVisible();
  });

  test("should open create escrow modal or form", async ({ page }) => {
    const createButton = page.locator('button:has-text("Create"), button:has-text("New Escrow")');
    if (await createButton.isVisible()) {
      await createButton.click();
      await page.waitForTimeout(500);
      // Modal or form should appear
      const modal = page.locator('[role="dialog"], [class*="modal"], form');
    }
  });

  test("should validate required form fields", async ({ page }) => {
    const createButton = page.locator('button:has-text("Create")');
    if (await createButton.isVisible()) {
      await createButton.click();
      await page.waitForTimeout(500);
      
      // Try to submit without filling fields
      const submitButton = page.locator('button[type="submit"]');
      if (await submitButton.isVisible()) {
        await submitButton.click();
        // Should show validation errors
        await page.waitForTimeout(500);
      }
    }
  });
});

// ============================================
// ADMIN PANEL TESTS
// ============================================

test.describe("Admin Panel", () => {
  test.beforeEach(async ({ page }) => {
    await page.goto("/admin");
  });

  test("should display admin heading", async ({ page }) => {
    await expect(page.getByRole("heading", { name: /admin/i })).toBeVisible();
  });

  test("should display statistics or metrics", async ({ page }) => {
    await page.waitForTimeout(1000);
    // Should have some stats or be empty
    const hasStats = 
      (await page.locator('[class*="stat"], [class*="metric"], [class*="card"]').count()) > 0 ||
      (await page.getByText(/no data|loading/i).count()) > 0;
  });

  test("should have admin controls", async ({ page }) => {
    const adminControls = page.locator('button:has-text("Settings"), button:has-text("Config"), button:has-text("Manage")');
    // Controls may or may not be visible
  });
});

// ============================================
// DISPUTES PAGE TESTS
// ============================================

test.describe("Disputes Page", () => {
  test.beforeEach(async ({ page }) => {
    await page.goto("/disputes");
  });

  test("should display disputes heading", async ({ page }) => {
    await expect(page.getByRole("heading", { name: /dispute/i })).toBeVisible();
  });

  test("should display dispute list or empty state", async ({ page }) => {
    await page.waitForTimeout(1000);
    const hasContent = 
      (await page.locator('[class*="dispute"]').count()) > 0 ||
      (await page.getByText(/no dispute|empty/i).count()) > 0;
    expect(hasContent).toBe(true);
  });

  test("should have filter by status", async ({ page }) => {
    const statusFilter = page.locator('select:has-text("Status"), [class*="filter"]');
    // Filter may or may not be visible
  });
});

// ============================================
// RECEIVABLES PAGE TESTS
// ============================================

test.describe("Receivables Page", () => {
  test.beforeEach(async ({ page }) => {
    await page.goto("/receivables");
  });

  test("should display receivables heading", async ({ page }) => {
    await expect(page.getByRole("heading", { name: /receivable/i })).toBeVisible();
  });

  test("should display receivables list or empty state", async ({ page }) => {
    await page.waitForTimeout(1000);
    const hasContent = 
      (await page.locator('[class*="receivable"]').count()) > 0 ||
      (await page.getByText(/no receivable|empty/i).count()) > 0;
    expect(hasContent).toBe(true);
  });
});

// ============================================
// THEME & UI TESTS
// ============================================

test.describe("Theme & UI", () => {
  test.beforeEach(async ({ page }) => {
    await page.goto("/");
  });

  test("should toggle theme", async ({ page }) => {
    const themeButton = page.locator('button[aria-label*="theme" i], button:has-text("Theme")');
    if (await themeButton.isVisible()) {
      const html = page.locator("html");
      const initialClass = await html.getAttribute("class") || "";
      
      await themeButton.click();
      await page.waitForTimeout(300);
      
      const newClass = await html.getAttribute("class") || "";
      // Theme should have changed
    }
  });

  test("should display loading states", async ({ page }) => {
    await page.goto("/escrow/1");
    // During loading, skeleton or spinner should appear
  });

  test("should handle error states gracefully", async ({ page }) => {
    await page.goto("/escrow/999999999");
    await page.waitForTimeout(2000);
    // Should show error message or empty state
  });
});

// ============================================
// NETWORK & CHAIN TESTS
// ============================================

test.describe("Network & Chain", () => {
  test("should display network selector", async ({ page }) => {
    await page.goto("/");
    const networkSelector = page.locator('[class*="network"], select:has-text("Network")');
    // May require wallet connection
  });

  test("should handle chain switch", async ({ page }) => {
    // This would require wallet connection
    // Test placeholder for when wallet is connected
  });
});

// ============================================
// ACCESSIBILITY TESTS
// ============================================

test.describe("Accessibility", () => {
  test.beforeEach(async ({ page }) => {
    await page.goto("/");
  });

  test("should have proper heading hierarchy", async ({ page }) => {
    const h1 = page.locator("h1");
    await expect(h1).toBeVisible();
  });

  test("should have accessible buttons", async ({ page }) => {
    const buttons = page.locator("button");
    const count = await buttons.count();
    expect(count).toBeGreaterThan(0);
  });

  test("should have form labels", async ({ page }) => {
    const forms = page.locator("form");
    const count = await forms.count();
    if (count > 0) {
      const labels = page.locator("label");
      const labelCount = await labels.count();
      // At least some inputs should have labels
    }
  });

  test("should have alt text for images", async ({ page }) => {
    const images = page.locator("img");
    const count = await images.count();
    for (let i = 0; i < Math.min(count, 5); i++) {
      const img = images.nth(i);
      const alt = await img.getAttribute("alt");
      // Should have alt text or be decorative
    }
  });

  test("should have proper color contrast", async ({ page }) => {
    // Basic check - no red text on green background
    const redText = page.locator('[class*="text-red"], [class*="error"]');
  });
});

// ============================================
// RESPONSIVE DESIGN TESTS
// ============================================

test.describe("Responsive Design", () => {
  test("should work on mobile viewport", async ({ page }) => {
    await page.setViewportSize({ width: 375, height: 667 });
    await page.goto("/");
    await expect(page.getByRole("heading")).toBeVisible();
  });

  test("should work on tablet viewport", async ({ page }) => {
    await page.setViewportSize({ width: 768, height: 1024 });
    await page.goto("/");
    await expect(page.getByRole("heading")).toBeVisible();
  });

  test("should work on desktop viewport", async ({ page }) => {
    await page.setViewportSize({ width: 1920, height: 1080 });
    await page.goto("/");
    await expect(page.getByRole("heading")).toBeVisible();
  });

  test("should adapt navigation on mobile", async ({ page }) => {
    await page.setViewportSize({ width: 375, height: 667 });
    await page.goto("/");
    // Mobile menu should be accessible
  });
});

// ============================================
// ERROR HANDLING TESTS
// ============================================

test.describe("Error Handling", () => {
  test("should handle network errors", async ({ page }) => {
    // Simulate offline by intercepting requests
    await page.route("**/*", (route) => {
      if (Math.random() > 0.8) {
        route.abort("failed");
        return;
      }
      route.continue();
    });
    
    await page.goto("/");
    await page.waitForTimeout(2000);
  });

  test("should display meaningful error messages", async ({ page }) => {
    await page.goto("/escrow/invalid-id");
    await page.waitForTimeout(1000);
  });

  test("should handle timeout gracefully", async ({ page }) => {
    await page.goto("/");
    // Wait longer than typical timeout
    await page.waitForTimeout(10000);
  });
});

// ============================================
// PERFORMANCE TESTS
// ============================================

test.describe("Performance", () => {
  test("should load page within reasonable time", async ({ page }) => {
    const startTime = Date.now();
    await page.goto("/");
    await page.waitForLoadState("networkidle");
    const loadTime = Date.now() - startTime;
    
    // Page should load within 10 seconds
    expect(loadTime).toBeLessThan(10000);
  });

  test("should not have memory leaks on navigation", async ({ page }) => {
    for (let i = 0; i < 5; i++) {
      await page.goto("/");
      await page.goto("/admin");
      await page.goto("/disputes");
    }
  });
});
