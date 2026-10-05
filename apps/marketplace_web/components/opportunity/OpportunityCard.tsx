import {
  ArrowRight,
  Handshake,
  MapPin,
} from "lucide-react";
import { Opportunity } from "@/types/marketplace";

function formatIDR(value?: number) {
  if (!value) return "-";

  return `Rp${new Intl.NumberFormat("id-ID").format(value)}`;
}

export default function OpportunityCard({
  opportunity,
}: {
  opportunity: Opportunity;
}) {
  return (
    <article className="nd-card nd-card-hover overflow-hidden">
      <div className="h-1.5 nd-red-gradient" />

      <div className="p-5 sm:p-6">
        <div className="flex items-start justify-between gap-4">
          <div className="grid size-12 place-items-center rounded-2xl bg-red-50 text-[#e5232e]">
            <Handshake size={22} />
          </div>

          <span className="rounded-full border border-red-100 bg-red-50 px-3 py-1 text-[9px] font-extrabold tracking-wide text-[#e5232e]">
            {opportunity.type}
          </span>
        </div>

        <h3 className="mt-5 text-lg font-black text-[#202329]">
          {opportunity.title}
        </h3>

        <p className="mt-1 text-sm font-semibold text-[#7a828d]">
          {opportunity.business.name}
        </p>

        <div className="mt-5 grid gap-3 sm:grid-cols-2">
          <div className="rounded-xl bg-[#f8f9fb] p-3">
            <div className="text-[10px] font-bold uppercase tracking-wide text-[#9198a2]">
              Modal mulai
            </div>

            <div className="mt-1 text-base font-black text-[#202329]">
              {formatIDR(opportunity.startingCapital)}
            </div>
          </div>

          <div className="rounded-xl bg-[#f8f9fb] p-3">
            <div className="text-[10px] font-bold uppercase tracking-wide text-[#9198a2]">
              Area
            </div>

            <div className="mt-1 flex items-start gap-1.5 text-xs font-bold leading-5 text-[#4e5661]">
              <MapPin size={13} className="mt-0.5 shrink-0 text-[#e5232e]" />
              {opportunity.area}
            </div>
          </div>
        </div>

        <p className="mt-4 text-xs leading-5 text-[#8b929c]">
          {opportunity.marginNote}
        </p>

        <button
          type="button"
          className="mt-5 flex w-full items-center justify-center gap-2 rounded-xl border border-[#dfe3e8] py-3 text-sm font-extrabold text-[#343941] transition hover:border-[#e5232e] hover:text-[#e5232e]"
        >
          Lihat Peluang
          <ArrowRight size={15} />
        </button>
      </div>
    </article>
  );
}