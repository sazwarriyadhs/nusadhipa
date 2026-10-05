"use client";

const columns = ["Business", "Legal Type", "Document", "Status"];

const rows = [
        ["Raja Telur","NIB","NIB-001","ACTIVE"],
        ["RM Abah Kenari","AHU","AHU-001","PENDING"],
        ["Bogor Fresh Farm","NIB","NIB-002","ACTIVE"],
        ["UMKM Cimahpar Jaya","KBLI","KBLI-003","PENDING"],

];

export default function Page() {
  return (
    <div className="page-content">
      <section className="panel-card">
        <h2 className="panel-title">Legal Control Center</h2>
        <div className="panel-subtitle">NIB, AHU, KBLI, applications and legal verification</div>

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

