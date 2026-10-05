"use client";

const columns = ["User", "Type", "Phone", "Status"];

const rows = [
        ["Budi Santoso","CUSTOMER","+62 812-xxx","ACTIVE"],
        ["Siti Rahma","CUSTOMER","+62 813-xxx","ACTIVE"],
        ["Abdul Rochmat","OWNER","+62 811-xxx","ACTIVE"],
        ["Andi Wijaya","STAFF","+62 815-xxx","SUSPENDED"],

];

export default function Page() {
  return (
    <div className="page-content">
      <section className="panel-card">
        <h2 className="panel-title">User Management</h2>
        <div className="panel-subtitle">Manage mobile users, owners, staff and administrators</div>

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

