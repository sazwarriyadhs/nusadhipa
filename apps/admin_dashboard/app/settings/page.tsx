export default function SettingsPage() {
  return (
    <div className="page-content">
      <section className="panel-card">
        <h2 className="panel-title">Settings</h2>
        <div className="panel-subtitle">
          Administrator and system configuration
        </div>

        <div style={{ marginTop: 22, lineHeight: 2 }}>
          <div><b>Application:</b> NUSA-DHIPA Admin Dashboard</div>
          <div><b>API Gateway:</b> http://localhost:8300</div>
          <div><b>Theme:</b> NUSA-DHIPA White / Red</div>
          <div><b>Environment:</b> Development</div>
        </div>
      </section>
    </div>
  );
}

