"use client";

import { useTheme as useNextTheme } from "next-themes";
import { ThemeProvider as NextThemesProvider, useTheme } from "next-themes";
import { useEffect, useState, type ReactNode } from "react";

interface ThemeProviderProps {
  children: ReactNode;
  attribute?: "class" | "data-theme";
  defaultTheme?: string;
  enableSystem?: boolean;
  disableTransitionOnChange?: boolean;
}

export function ThemeProvider({ 
  children, 
  attribute = "class",
  defaultTheme = "dark",
  enableSystem = true,
  disableTransitionOnChange = true
}: ThemeProviderProps) {
  const [mounted, setMounted] = useState(false);

  useEffect(() => {
    setMounted(true);
  }, []);

  // Prevent flash of wrong theme - don't render until mounted
  if (!mounted) {
    return <>{children}</>;
  }

  return (
    <NextThemesProvider
      attribute={attribute}
      defaultTheme={defaultTheme}
      enableSystem={enableSystem}
      disableTransitionOnChange={disableTransitionOnChange}
    >
      <div style={{ minHeight: "100vh" }}>
        {children}
      </div>
    </NextThemesProvider>
  );
}

// Hook to use theme in components
export function useThemeToggle() {
  const { theme, setTheme, resolvedTheme } = useTheme();
  const [mounted, setMounted] = useState(false);

  useEffect(() => {
    setMounted(true);
  }, []);

  const toggleTheme = () => {
    setTheme(resolvedTheme === "dark" ? "light" : "dark");
  };

  // Default to dark mode until mounted to prevent hydration mismatch
  // This ensures server and initial client render match
  const isDark = mounted 
    ? resolvedTheme === "dark" || theme === "dark"
    : true;

  return {
    theme: mounted ? (resolvedTheme || theme) : "dark",
    toggleTheme,
    isDark
  };
}
