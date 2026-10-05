"use client";

const columns = ["Business", "Plan", "Period", "Status"];

const rows = [
        ["Raja Telur","Marketplace Basic","30 days","ACTIVE"],
        ["RM Abah Kenari","Business","Monthly","ACTIVE"],
        ["UMKM Cimahpar Jaya","Marketplace Basic","Trial","PENDING"],

];

export default function Page() {
  return (
    <div className="page-content">
      <section className="panel-card">
        <h2 className="panel-title">Subscription Management</h2>
        <div className="panel-subtitle">Monitor active, trial and expired subscriptions</div>

        <div className="table-scroll">
          <table>
            <thead>
              <tr>
                {columns.map((column) => (
                  <th key={column}>{column}</th>
                ))}
              </tr>
            </thead>

            <tbody>
              {rows.map((row, rowIndex) => (
                <tr key={rowIndex}>
                  {row.map((value, index) => (
                    <td key={index}>
                      {index === row.length - 1 ? (
                        <span className={
                          "badge " +
                          (value === "ACTIVE"
                            ? "badge-active"
                            : value === "SUSPENDED"
                              ? "badge-suspended"
                              : "badge-pending")
                        }>
                          {value}
                        </span>
                      ) : (
                        value
                      )}
                    </td>
                  ))}
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </section>
    </div>
  );
}

