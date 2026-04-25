using System;
using System.Collections.Generic;
using System.IO;
using System.Diagnostics;
using System.Security.Principal;
using Microsoft.Win32;

// =============================================================================
// RegistryCleaner.cs - Complete Registry Cleaner from Leedeo Cleaner repo:
// https://github.com/Leedeo/Leedeo-Cleaner/blob/main/MainWindow.cs
// Standalone console application for safe registry cleaning
// Safe scope: orphaned uninstall entries, broken Run/RunOnce autostart entries,
// and stale MRU (recently used files) lists.
// Never touches: COM, shell extensions, file associations, services, drivers,
// or anything under HKLM\SYSTEM.
// =============================================================================

[System.Runtime.Versioning.SupportedOSPlatform("windows")]
class RegistryCleaner
{
    private List<string[]> toDelete = new List<string[]>();

    static void Main(string[] args)
    {
        try
        {
            // Check for administrator privileges
            WindowsPrincipal principal = new WindowsPrincipal(WindowsIdentity.GetCurrent());
            if (!principal.IsInRole(WindowsBuiltInRole.Administrator))
            {
                Console.WriteLine("ERROR: This application requires Administrator privileges.");
                Console.WriteLine("Please run as Administrator.");
                Console.ReadKey();
                return;
            }

            RegistryCleaner cleaner = new RegistryCleaner();

            // Backup registry before scanning
            Console.WriteLine("[*] Creating backup of registry");
            cleaner.BackupRegistry();
            Console.WriteLine("[OK] Registry backup created");
            Console.WriteLine();

            // Scan for issues
            Console.WriteLine("[*] Scanning registry");
            Console.WriteLine();
            cleaner.ScanRegistry();

            // Show findings
            if (cleaner.toDelete.Count == 0)
            {
                Console.WriteLine();
                Console.WriteLine("COMPLETED: Registry is clean!");
                Console.WriteLine("No orphaned entries found.");
                Console.WriteLine();
                Console.ReadKey();
                return;
            }

            Console.WriteLine();
            Console.WriteLine("FINDINGS: {0} issues detected", cleaner.toDelete.Count);
            Console.WriteLine();

            foreach (string[] entry in cleaner.toDelete)
            {
                Console.WriteLine("  [{0}] {1}", entry[0], entry[3]);
            }

            Console.WriteLine();

            // Confirm before deleting
            Console.WriteLine("WARNING: These entries will be deleted from your registry.");
            Console.Write("Continue with cleanup? [Y/N]: ");
            string? confirm = Console.ReadLine();

            if (!string.Equals(confirm, "Y", StringComparison.OrdinalIgnoreCase))
            {
                Console.WriteLine("Cleanup cancelled by user.");
                Console.ReadKey();
                return;
            }

            Console.WriteLine();
            Console.WriteLine("[*] Deleting entries");
            Console.WriteLine();

            // Delete entries
            int deleted = 0, failed = 0;
            foreach (string[] entry in cleaner.toDelete)
            {
                try
                {
                    string hive = entry[0];
                    string keyPath = entry[1];
                    string valName = entry[2];

                    var rootKey = hive == "HKLM"
                        ? Registry.LocalMachine
                        : Registry.CurrentUser;

                    if (string.IsNullOrEmpty(valName))
                    {
                        // Delete entire subkey (orphaned uninstall entry)
                        string? parent = Path.GetDirectoryName(keyPath);
                        string child = Path.GetFileName(keyPath);
                        if (parent == null) { failed++; continue; }

                        using (var parentKey = rootKey.OpenSubKey(parent, true))
                        {
                            if (parentKey != null)
                            {
                                parentKey.DeleteSubKeyTree(child, false);
                                Console.WriteLine("  ✓ {0}", entry[3]);
                                deleted++;
                            }
                            else { failed++; }
                        }
                    }
                    else
                    {
                        // Delete single value (Run entry or MRU entry)
                        using (var key = rootKey.OpenSubKey(keyPath, true))
                        {
                            if (key != null)
                            {
                                key.DeleteValue(valName, false);
                                Console.WriteLine("  ✓ {0}", entry[3]);
                                deleted++;
                            }
                            else { failed++; }
                        }
                    }
                }
                catch (Exception ex)
                {
                    Console.WriteLine("  ✗ {0} — {1}", entry[3], ex.Message);
                    failed++;
                }
            }

            Console.WriteLine();
            Console.WriteLine("RESULTS: {0} deleted, {1} failed", deleted, failed);
            Console.WriteLine();

            if (failed == 0)
            {
                Console.WriteLine("SUCCESS: All entries were deleted successfully!");
            }
            else
            {
                Console.WriteLine("WARNING: Some entries could not be deleted.");
                Console.WriteLine("Check permissions and try running as Administrator.");
            }

            Console.WriteLine();
            Console.ReadKey();
        }
        catch (Exception ex)
        {
            Console.WriteLine("ERROR: {0}", ex.Message);
            Console.WriteLine(ex.StackTrace);
            Console.ReadKey();
        }
    }

    // =========================================================================
    // MAIN SCANNING LOGIC
    // =========================================================================

    private void ScanRegistry()
    {
        Console.WriteLine("[1/3] Scanning ZONE 1: Orphaned uninstall entries");
        ScanUninstallEntries();
        Console.WriteLine("      Found: {0}", CountEntriesInZone("HKLM"));
        Console.WriteLine();

        Console.WriteLine("[2/3] Scanning ZONE 2: Broken Run/RunOnce autostart entries");
        ScanRunOnceEntries();
        Console.WriteLine("      Found: {0}", CountEntriesInZone("HKCU"));
        Console.WriteLine();

        Console.WriteLine("[3/3] Scanning ZONE 3: Stale MRU (recently used files)");
        ScanMRUEntries();
        Console.WriteLine("      Found: {0}", CountEntriesInZone("MRU"));
        Console.WriteLine();
    }

    // ── ZONE 1: Orphaned uninstall entries ────────────────────────────────────
    // Checks both 32-bit and 64-bit uninstall hives.
    // An entry is flagged only when BOTH UninstallString AND DisplayIcon
    // point to paths that do not exist — requiring both conditions avoids
    // false positives from entries that use non-standard install layouts.
    private void ScanUninstallEntries()
    {
        string[] uninstallHives = {
            @"SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall",
            @"SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
        };

        foreach (string hive in uninstallHives)
        {
            try
            {
                using (var key = Registry.LocalMachine.OpenSubKey(hive))
                {
                    if (key == null) continue;

                    foreach (string subName in key.GetSubKeyNames())
                    {
                        try
                        {
                            using (var sub = key.OpenSubKey(subName))
                            {
                                if (sub == null) continue;

                                // Skip Windows system components and update entries — never touch these
                                object? sysComp = sub.GetValue("SystemComponent");
                                if (sysComp != null && sysComp.ToString() == "1") continue;
                                if (sub.GetValue("ReleaseType") != null) continue;

                                string uninstStr = ((sub.GetValue("UninstallString") ?? "").ToString() ?? "").Trim('"', ' ');
                                string displayIcon = ((sub.GetValue("DisplayIcon") ?? "").ToString() ?? "").Split(',')[0].Trim('"', ' ');
                                string displayName = ((sub.GetValue("DisplayName") ?? subName).ToString()) ?? subName;

                                // Skip MSI-managed entries — they may not have a direct exe path
                                if (uninstStr.StartsWith("MsiExec", StringComparison.OrdinalIgnoreCase)) continue;
                                if (uninstStr.StartsWith("msiexec", StringComparison.OrdinalIgnoreCase)) continue;

                                string exeDir = Path.GetDirectoryName(uninstStr) ?? "";
                                string iconDir = Path.GetDirectoryName(displayIcon) ?? "";

                                bool uninstMissing = !string.IsNullOrEmpty(uninstStr) && !File.Exists(uninstStr) && !Directory.Exists(exeDir);
                                bool iconMissing = !string.IsNullOrEmpty(displayIcon) && !File.Exists(displayIcon) && !Directory.Exists(iconDir);

                                if (uninstMissing && iconMissing)
                                    toDelete.Add(new string[] { "HKLM", hive + @"\" + subName, "", displayName });
                            }
                        }
                        catch { }
                    }
                }
            }
            catch { }
        }
    }

    // ── ZONE 2: Broken Run / RunOnce autostart entries ────────────────────────
    // Only HKCU — HKLM Run entries often belong to drivers and services
    // that load differently and would generate too many false positives.
    private void ScanRunOnceEntries()
    {
        string[] runKeys = {
            @"SOFTWARE\Microsoft\Windows\CurrentVersion\Run",
            @"SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce"
        };

        foreach (string runKey in runKeys)
        {
            try
            {
                using (var key = Registry.CurrentUser.OpenSubKey(runKey))
                {
                    if (key == null) continue;

                    foreach (string valueName in key.GetValueNames())
                    {
                        try
                        {
                            string raw = (key.GetValue(valueName) ?? "").ToString() ?? "";
                            // Extract executable path — strip quotes and arguments
                            string exePath = raw.Trim().TrimStart('"');
                            int endQuote = exePath.IndexOf('"');
                            if (endQuote > 0) exePath = exePath.Substring(0, endQuote);
                            exePath = exePath.Trim();

                            if (!string.IsNullOrEmpty(exePath) && !File.Exists(exePath))
                                toDelete.Add(new string[] { "HKCU", runKey, valueName, valueName + " → " + exePath });
                        }
                        catch { }
                    }
                }
            }
            catch { }
        }
    }

    // ── ZONE 3: Stale MRU (recently used files) string entries ────────────────
    // Only string values with a rooted path — binary PIDL values are skipped
    // entirely because they cannot be decoded safely without Shell APIs.
    private void ScanMRUEntries()
    {
        string[] mruPaths = {
            @"SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\RecentDocs",
            @"SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\ComDlg32\OpenSavePidlMRU",
            @"SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\ComDlg32\LastVisitedPidlMRU"
        };

        foreach (string mruPath in mruPaths)
        {
            try
            {
                using (var key = Registry.CurrentUser.OpenSubKey(mruPath))
                {
                    if (key == null) continue;

                    foreach (string valueName in key.GetValueNames())
                    {
                        if (valueName.Equals("MRUListEx", StringComparison.OrdinalIgnoreCase) ||
                            valueName.Equals("MRUList", StringComparison.OrdinalIgnoreCase)) continue;

                        try
                        {
                            object? val = key.GetValue(valueName);
                            // C# 5 compatible type check — no pattern matching
                            string? strVal = val as string;
                            if (strVal != null)
                            {
                                string filePath = strVal.Trim();
                                if (!string.IsNullOrEmpty(filePath)
                                    && Path.IsPathRooted(filePath)
                                    && !File.Exists(filePath)
                                    && !Directory.Exists(filePath))
                                    toDelete.Add(new string[] { "HKCU", mruPath, valueName, filePath });
                            }
                        }
                        catch { }
                    }
                }
            }
            catch { }
        }
    }

    // =========================================================================
    // UTILITY METHODS
    // =========================================================================

    private void BackupRegistry()
    {
        string? backupHome = Environment.GetEnvironmentVariable("REGISTRY_BACKUP_HOME");
        string? keepStr = Environment.GetEnvironmentVariable("REGISTRY_BACKUP_TO_KEEP");

        if (string.IsNullOrEmpty(backupHome))
            throw new InvalidOperationException("Environment variable REGISTRY_BACKUP_HOME is not set");
        if (string.IsNullOrEmpty(keepStr))
            throw new InvalidOperationException("Environment variable REGISTRY_BACKUP_TO_KEEP is not set");

        if (!Directory.Exists(backupHome))
            Directory.CreateDirectory(backupHome);

        int keepCount;
        if (!int.TryParse(keepStr, out keepCount) || keepCount < 1)
            throw new InvalidOperationException("REGISTRY_BACKUP_TO_KEEP must be a positive integer");

        string timestamp = DateTime.Now.ToString("yyyy-MM-dd_HHmmss");

        ExportRegistryHive("HKCU", backupHome, timestamp);

        CleanupOldBackups(backupHome, keepCount);

        Console.WriteLine("      Backups saved to: {0}", backupHome);
        Console.WriteLine("      Retaining up to {0} backup(s)", keepCount);
    }

    private void ExportRegistryHive(string hive, string backupHome, string timestamp)
    {
        string backupPath = Path.Combine(backupHome, string.Format("Registry_Backup_{0}_{1}.reg", hive, timestamp));

        ProcessStartInfo psi = new ProcessStartInfo
        {
            FileName = "reg.exe",
            Arguments = "export \"" + hive + "\" \"" + backupPath + "\" /y",
            CreateNoWindow = true,
            UseShellExecute = false,
            WindowStyle = ProcessWindowStyle.Hidden
        };

        using (Process? p = Process.Start(psi))
        {
            p?.WaitForExit();
        }

        Console.WriteLine("      [{0}] Exported to: {1}", hive, backupPath);
    }

    private void CleanupOldBackups(string backupHome, int keepCount)
    {
        var backupFiles = Directory.GetFiles(backupHome, "Registry_Backup_*.reg")
            .Select(f => new FileInfo(f))
            .OrderByDescending(f => f.LastWriteTime)
            .ToList();

        if (backupFiles.Count <= keepCount)
            return;

        int deleted = 0;
        foreach (var file in backupFiles.Skip(keepCount))
        {
            try
            {
                file.Delete();
                deleted++;
                Console.WriteLine("      [CLEANUP] Removed old backup: {0}", file.Name);
            }
            catch (Exception ex)
            {
                Console.WriteLine("      [CLEANUP] Could not delete {0}: {1}", file.Name, ex.Message);
            }
        }

        Console.WriteLine("      [CLEANUP] Deleted {0} old backup(s)", deleted);
    }

    private int CountEntriesInZone(string zone)
    {
        int count = 0;
        foreach (string[] entry in toDelete)
        {
            if (entry[0] == zone || (zone == "HKCU" && entry[0] == "HKCU") || 
                (zone == "MRU" && entry[2].Contains("Recent")))
                count++;
        }
        return count;
    }
}
