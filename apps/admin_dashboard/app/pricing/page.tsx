"use client";

const columns = ["Plan", "Category", "Price", "Status"];

const rows = [
        ["Digital Entry","Legalitas","Rp 50.000","ACTIVE"],
        ["PT Perorangan","Legalitas","Rp 50.000","ACTIVE"],
        ["CV","Legalitas","Rp 75.000","ACTIVE"],
        ["PT","Legalitas","Rp 100.000","ACTIVE"],
        ["Marketplace Basic","Marketplace","Rp 50.000","ACTIVE"],

];

export default function Page() {
  return (
    <div className="page-content">
      <section className="panel-card">
        <h2 className="panel-title">Pricing Management</h2>
        <div className="panel-subtitle">Manage pricing plans and the Business OS pricing engine</div>

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

