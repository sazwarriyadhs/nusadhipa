"use client";

const columns = ["Service", "Port", "Health", "Status"];

const rows = [
        ["API Gateway","8300","Healthy","ACTIVE"],
        ["Auth","8301","Healthy","ACTIVE"],
        ["Tenant","8302","Healthy","ACTIVE"],
        ["Business","8303","Healthy","ACTIVE"],
        ["Catalog","8304","Healthy","ACTIVE"],
        ["Order","8305","Healthy","ACTIVE"],
        ["Legal","8327","Healthy","ACTIVE"],

];

export default function Page() {
  return (
    <div className="page-content">
      <section className="panel-card">
        <h2 className="panel-title">System Health</h2>
        <div className="panel-subtitle">NUSA-DHIPA infrastructure and service monitoring</div>

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

