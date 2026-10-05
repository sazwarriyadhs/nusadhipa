"use client";

const columns = ["Order", "Business", "Customer", "Status"];

const rows = [
        ["#ORD-10281","Raja Telur","Customer 01","ACTIVE"],
        ["#ORD-10280","RM Abah Kenari","Customer 02","PENDING"],
        ["#ORD-10279","Raja Telur","Customer 03","ACTIVE"],

];

export default function Page() {
  return (
    <div className="page-content">
      <section className="panel-card">
        <h2 className="panel-title">Order Management</h2>
        <div className="panel-subtitle">Monitor marketplace orders across the ecosystem</div>

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

