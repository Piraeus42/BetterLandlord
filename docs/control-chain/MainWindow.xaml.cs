using System.Windows;
using Piraeus.BetterLandlord.UI.Ipc;
using Piraeus.BetterLandlord.UI.ViewModels;

namespace Piraeus.BetterLandlord.UI;

public partial class MainWindow : Window
{
    private readonly UiPipeClient _pipeClient;
    private readonly HistoryViewModel _viewModel;
    private bool _seedDialogOpen;
    private bool _firstShow = true;

    public MainWindow()
    {
        InitializeComponent();

        _pipeClient = new UiPipeClient();
        _viewModel = new HistoryViewModel(_pipeClient);
        DataContext = _viewModel;

        Loaded += OnWindowLoaded;
        Closed += OnWindowClosed;
        Closing += OnWindowClosing;
    }

    /// <summary>
    /// Connect pipe + push listener without showing the window.
    /// Called once at app startup.
    /// </summary>
    public void ConnectPipe()
    {
        _pipeClient.OnPushMessage += HandlePushMessage;
        _pipeClient.Start();
    }

    private void OnWindowLoaded(object sender, RoutedEventArgs e)
    {
        if (_firstShow)
        {
            _firstShow = false;
            Focusable = true;
            PreviewKeyDown += OnPreviewKeyDown;
        }
    }

    private void HandlePushMessage(string json)
    {
        if (!Dispatcher.CheckAccess())
        {
            Dispatcher.BeginInvoke(() => HandlePushMessage(json));
            return;
        }

        var type = PeekType(json);
        switch (type)
        {
            case "seed_request":
                ShowSeedDialog();
                break;

            case "show_history":
                ShowFromTray();
                break;

            case "seed_updated":
                break;

            case "push_connected":
                break;
        }
    }

    private void ShowFromTray()
    {
        if (Visibility == Visibility.Visible) return;

        Show();
        WindowState = WindowState.Normal;
        Activate();
        // WPF hack: Topmost toggle forces window to front over Godot fullscreen
        Topmost = true;
        Topmost = false;
    }

    private static string PeekType(string json)
    {
        try
        {
            var doc = System.Text.Json.JsonDocument.Parse(json);
            return doc.RootElement.TryGetProperty("type", out var t) ? t.GetString() ?? "" : "";
        }
        catch { return ""; }
    }

    private void OnPreviewKeyDown(object sender, System.Windows.Input.KeyEventArgs e)
    {
        if (e.Key == System.Windows.Input.Key.Left)
        {
            _viewModel.CycleRankMode(-1);
            e.Handled = true;
        }
        else if (e.Key == System.Windows.Input.Key.Right)
        {
            _viewModel.CycleRankMode(1);
            e.Handled = true;
        }
    }

    private void RankPrev_Click(object sender, RoutedEventArgs e)
    {
        _viewModel.CycleRankMode(-1);
    }

    private void RankNext_Click(object sender, RoutedEventArgs e)
    {
        _viewModel.CycleRankMode(1);
    }

    private bool _reallyClosing;

    private void OnWindowClosing(object? sender, System.ComponentModel.CancelEventArgs e)
    {
        if (!_reallyClosing)
        {
            e.Cancel = true;
            Hide();
        }
    }

    private void OnWindowClosed(object? sender, EventArgs e)
    {
    }

    public void Cleanup()
    {
        _reallyClosing = true;
        _pipeClient.OnPushMessage -= HandlePushMessage;
        _pipeClient.SendClose();
        _pipeClient.Dispose();
        Close();
    }

    private void ShowSeedDialog()
    {
        if (_seedDialogOpen)
            return;

        _seedDialogOpen = true;
        try
        {
            var dialog = new SeedDialog(_pipeClient);
            dialog.ShowDialog();
        }
        finally
        {
            _seedDialogOpen = false;
        }
    }

    private void ToggleSummary_Click(object sender, RoutedEventArgs e)
    {
        _viewModel.ToggleSummary();
    }

    private void CopySeed_Click(object sender, RoutedEventArgs e)
    {
        var seed = _viewModel.MetaSeed;
        if (!string.IsNullOrEmpty(seed))
        {
            var dataObj = new DataObject();
            dataObj.SetData(DataFormats.UnicodeText, seed, false);
            Clipboard.SetDataObject(dataObj, true);
            _viewModel.StatusText = $"Seed copied: {seed}";
        }
    }
}
