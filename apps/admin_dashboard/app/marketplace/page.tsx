"use client";

const columns = ["Item", "Business", "Type", "Status"];

const rows = [
        ["Telur Asin","Raja Telur","PRODUCT","ACTIVE"],
        ["Telur Ayam","Raja Telur","PRODUCT","ACTIVE"],
        ["Nasi Goreng","RM Abah Kenari","PRODUCT","ACTIVE"],
        ["Catering","RM Abah Kenari","SERVICE","PENDING"],

];

export default function Page() {
  return (
    <div className="page-content">
      <section className="panel-card">
        <h2 className="panel-title">Marketplace Management</h2>
        <div className="panel-subtitle">Products, services, categories and moderation</div>

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

