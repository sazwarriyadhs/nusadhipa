"use client";

const columns = ["Business", "Category", "Owner", "Status"];

const rows = [
        ["Raja Telur","Retail","Owner","ACTIVE"],
        ["RM Abah Kenari","Restaurant","Abdul Rochmat","ACTIVE"],
        ["Bogor Fresh Farm","Agriculture","Owner","ACTIVE"],
        ["UMKM Cimahpar Jaya","Food","Owner","PENDING"],

];

export default function Page() {
  return (
    <div className="page-content">
      <section className="panel-card">
        <h2 className="panel-title">Tenant / UMKM Management</h2>
        <div className="panel-subtitle">Manage businesses, branches and tenant verification</div>

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

