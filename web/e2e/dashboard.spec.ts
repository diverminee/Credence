import { test, expect } from "@playwright/test";

test.describe("Dashboard Page", () => {
  test.beforeEach(async ({ page }) => {
    await page.goto("/");
  });

  test("should display page title", async ({ page }) => {
    await expect(page.getByRole("heading", { name: "Dashboard" })).toBeVisible();
  });

  test("should show connect wallet prompt when disconnected", async ({ page }) => {
    await expect(page.getByText("Connect Your Wallet")).toBeVisible();
  });

  test("should have working navigation links", async ({ page }) => {
    // Check header navigation exists
    await expect(page.getByRole("navigation")).toBeVisible();
  });

  test("should be responsive on mobile", async ({ page }) => {
    await page.setViewportSize({ width: 375, height: 667 });
    await expect(page.getByRole("heading", { name: "Dashboard" })).toBeVisible();
  });
});

test.describe("Navigation", () => {
  test.beforeEach(async ({ page }) => {
    await page.goto("/");
  });

  test("should navigate to admin page", async ({ page }) => {
    await page.goto("/admin");
    await expect(page.getByRole("heading", { name: "Admin" })).toBeVisible();
  });

  test("should navigate to disputes page", async ({ page }) => {
    await page.goto("/disputes");
    await expect(page.getByRole("heading", { name: "Disputes" })).toBeVisible();
  });

  test("should navigate to receivables page", async ({ page }) => {
    await page.goto("/receivables");
    await expect(page.getByRole("heading", { name: "Receivables" })).toBeVisible();
  });
});
