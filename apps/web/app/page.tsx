import { Button } from "@/components/ui/button";

export default function Home() {
  return (
    <main className="flex min-h-screen flex-col items-center justify-center px-4">
      <div className="max-w-2xl space-y-6 text-center">
        <div
          className="inline-block rounded-full px-4 py-1 text-sm font-medium text-white"
          style={{ backgroundColor: "#18a563" }}
        >
          Scaffolded by Forge
        </div>
        <h1 className="text-5xl font-bold tracking-tight">GABAG Operations Platform</h1>
        <p className="text-muted-foreground text-xl leading-relaxed">
          Swiss manufacturer of sanitary installation systems
        </p>
        <div className="flex justify-center gap-4 pt-4">
          <Button size="lg" style={{ backgroundColor: "#18a563" }}>
            Get started
          </Button>
          <Button size="lg" variant="outline">
            Documentation
          </Button>
        </div>
      </div>
    </main>
  );
}
