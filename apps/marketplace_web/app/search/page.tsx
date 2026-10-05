import { Suspense } from "react";
import Header from "@/components/layout/Header";
import SearchResults from "@/components/search/SearchResults";

function SearchLoading() {
  return (
    <main className="bg-[#f8f9fb]">
      <div className="container py-14">
        <div className="animate-pulse">
          <div className="h-3 w-24 rounded bg-gray-200" />
          <div className="mt-4 h-10 w-64 rounded bg-gray-200" />
          <div className="mt-8 h-40 rounded-2xl bg-gray-200" />
        </div>
      </div>
    </main>
  );
}

export default function SearchPage() {
  return (
    <>
      <Header />

      <Suspense fallback={<SearchLoading />}>
        <SearchResults />
      </Suspense>
    </>
  );
}