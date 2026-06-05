using System.Windows;
using System.Windows.Threading;

namespace Piraeus.BetterLandlord.UI;

public partial class App : Application
{
    public static string? DataDir { get; private set; }

    protected override void OnStartup(StartupEventArgs e)
    {
        for (int i = 0; i < e.Args.Length; i++)
        {
            if (e.Args[i] == "--data-dir" && i + 1 < e.Args.Length)
                DataDir = e.Args[i + 1];
        }

        base.OnStartup(e);

        DispatcherUnhandledException += (s, args) =>
        {
            MessageBox.Show($"Unhandled UI error:\n\n{args.Exception.Message}\n\n{args.Exception.StackTrace}",
                "Better Landlord — Error", MessageBoxButton.OK, MessageBoxImage.Error);
            args.Handled = true;
        };

        AppDomain.CurrentDomain.UnhandledException += (s, args) =>
        {
            var ex = args.ExceptionObject as Exception;
            MessageBox.Show($"Fatal error:\n\n{ex?.ToString() ?? "Unknown"}",
                "Better Landlord — Fatal Error", MessageBoxButton.OK, MessageBoxImage.Error);
        };

        TaskScheduler.UnobservedTaskException += (s, args) =>
        {
            MessageBox.Show($"Task error:\n\n{args.Exception.Message}",
                "Better Landlord — Task Error", MessageBoxButton.OK, MessageBoxImage.Error);
            args.SetObserved();
        };

        // WPF stays resident — closing window hides it, doesn't exit.
        ShutdownMode = ShutdownMode.OnExplicitShutdown;
        var mainWindow = new MainWindow();
        MainWindow = mainWindow;
        mainWindow.ConnectPipe();  // connect pipe + push listener, no Show()
    }

    protected override void OnExit(ExitEventArgs e)
    {
        if (MainWindow is MainWindow mw)
            mw.Cleanup();
        base.OnExit(e);
    }
}
