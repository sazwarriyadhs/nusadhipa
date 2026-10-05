"use client";

const columns = ["Report", "Period", "Records", "Status"];

const rows = [
        ["Business Overview","Monthly","2,431","ACTIVE"],
        ["Marketplace Sales","Monthly","15,820","ACTIVE"],
        ["Legalitas","Monthly","1,284","ACTIVE"],
        ["Revenue","Monthly","Rp 284.6M","ACTIVE"],

];

export default function Page() {
  return (
    <div className="page-content">
      <section className="panel-card">
        <h2 className="panel-title">Reports</h2>
        <div className="panel-subtitle">Business, marketplace, legalitas and revenue reporting</div>

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

