"use client";

const columns = ["Actor", "Action", "Module", "Status"];

const rows = [
        ["Administrator","User verification","Users","ACTIVE"],
        ["Administrator","Business update","Tenants","ACTIVE"],
        ["System","Order synchronization","Orders","ACTIVE"],
        ["Administrator","Legal review","Legal","ACTIVE"],

];

export default function Page() {
  return (
    <div className="page-content">
      <section className="panel-card">
        <h2 className="panel-title">Audit Logs</h2>
        <div className="panel-subtitle">Track administrator and system activities</div>

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

