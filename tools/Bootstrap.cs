// Turbo Old PC bootstrapper — .NET Framework 4.5+; Windows only.
// Two flavors compiled from exactly the same verified payload:
// installer: /define:INSTALLER ; portable: no define
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.IO.Compression;
using System.Reflection;
using System.Security.Cryptography;
using System.Text;
using System.Windows.Forms;

internal static class Bootstrap
{
    [STAThread]
    private static int Main()
    {
        string stage = null;
        try
        {
            stage = Path.Combine(Path.GetTempPath(), "TurboOldPC-" + Guid.NewGuid().ToString("N"));
            Directory.CreateDirectory(stage);
            using (Stream stream = Assembly.GetExecutingAssembly().GetManifestResourceStream("turbo_payload.zip"))
            {
                if (stream == null) throw new InvalidOperationException("Embedded application payload missing.");
                using (ZipArchive archive = new ZipArchive(stream, ZipArchiveMode.Read))
                {
                    long total = 0;
                    var seen = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
                    foreach (ZipArchiveEntry entry in archive.Entries)
                    {
                        string name = entry.FullName.Replace('/', '\\');
                        if (name.Length == 0 || name.StartsWith("\\", StringComparison.Ordinal) ||
                            name.Contains(":") || name.IndexOfAny(new char[] { '\0' }) >= 0 ||
                            Path.IsPathRooted(name)) throw new InvalidDataException("Unsafe ZIP entry.");
                        string destination = Path.GetFullPath(Path.Combine(stage, name));
                        string prefix = Path.GetFullPath(stage) + Path.DirectorySeparatorChar;
                        if (!destination.StartsWith(prefix, StringComparison.OrdinalIgnoreCase))
                            throw new InvalidDataException("ZIP traversal detected.");
                        if (!seen.Add(destination)) throw new InvalidDataException("Duplicate ZIP path.");
                        // Reject file and folder collisions and large decompression bombs.
                        if (entry.Length > 20L * 1024 * 1024) throw new InvalidDataException("Oversized entry.");
                        total += entry.Length;
                        if (total > 80L * 1024 * 1024) throw new InvalidDataException("Oversized application.");
                        if (name.EndsWith("\\", StringComparison.Ordinal))
                        {
                            Directory.CreateDirectory(destination);
                            continue;
                        }
                        Directory.CreateDirectory(Path.GetDirectoryName(destination));
                        using (Stream file = new FileStream(destination, FileMode.CreateNew, FileAccess.Write, FileShare.None))
                        using (Stream item = entry.Open())
                        {
                            byte[] buffer = new byte[32768];
                            long written = 0;
                            int read;
                            while ((read = item.Read(buffer, 0, buffer.Length)) > 0)
                            {
                                written += read;
                                if (written > entry.Length || written > 20L * 1024 * 1024)
                                    throw new InvalidDataException("Decompressed payload exceeded declared size.");
                                file.Write(buffer, 0, read);
                            }
                            if (written != entry.Length) throw new InvalidDataException("Truncated archive item.");
                        }
                    }
                }
            }
#if INSTALLER
            string app = Path.Combine(stage, "install", "Install.ps1");
#else
            string app = Path.Combine(stage, "app", "TurboOldPC.ps1");
#endif
            if (!File.Exists(app)) throw new FileNotFoundException("Main script is missing", app);
            string ps = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.Windows),
                "System32", "WindowsPowerShell", "v1.0", "powershell.exe");
            if (!File.Exists(ps)) throw new FileNotFoundException("Windows PowerShell 5.1 unavailable", ps);
            var args = "-NoLogo -NoProfile -STA -ExecutionPolicy Bypass -File \"" + app.Replace("\"", "") + "\"";
            var info = new ProcessStartInfo(ps, args);
            info.UseShellExecute = false;
            info.CreateNoWindow = true;
            info.WindowStyle = ProcessWindowStyle.Hidden;
            using (Process child = Process.Start(info))
            {
                if (child == null) throw new InvalidOperationException("Could not start application.");
                child.WaitForExit();
                if (child.ExitCode != 0)
                {
                    MessageBox.Show("Turbo Old PC returned code " + child.ExitCode +
                        ". Open Start.cmd from the sources for detailed diagnostics.",
                        "Turbo Old PC", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                }
                return child.ExitCode;
            }
        }
        catch (Exception e)
        {
            MessageBox.Show("Unable to launch Turbo Old PC:\n" + e.Message,
                "Turbo Old PC", MessageBoxButtons.OK, MessageBoxIcon.Error);
            return 1;
        }
        finally
        {
            if (stage != null)
            {
                try { Directory.Delete(stage, true); }
                catch { /* OS may still hold files until all readers exit. */ }
            }
        }
    }
}
