type Level = "debug" | "info" | "warn" | "error";
type Context = Record<string, unknown>;

const isDev = typeof process !== 'undefined' ? process.env.NODE_ENV === "development" : true;

function createLog(serviceName: string) {
  return function log(level: Level, context: Context, message: string) {
    const entry = {
      level,
      time: new Date().toISOString(),
      service: serviceName,
      ...context,
      msg: message,
    };

    if (isDev) {
      const prefix = { debug: "🔍", info: "ℹ️ ", warn: "⚠️ ", error: "❌" }[level];
      const out = `${prefix} ${message}`;
      
      try {
        if (level === "error") {
          console.error(out);
          if (context && Object.keys(context).length) console.error(context);
        } else if (level === "warn") {
          console.warn(out);
          if (context && Object.keys(context).length) console.warn(context);
        } else {
          console.log(out);
          if (context && Object.keys(context).length) console.log(context);
        }
      } catch (e) {
        console.log(out, "[Context suppressed]");
      }
    } else {
      try {
        const json = JSON.stringify(entry);
        if (level === "error") console.error(json);
        else if (level === "warn") console.warn(json);
        else if (level === "info") console.info(json);
        else console.log(json);
      } catch (e) {
        console.log(`[Logger Error] Failed to stringify entry for level ${level}`);
      }
    }
  };
}

export function createLogger(serviceName: string) {
  const log = createLog(serviceName);
  
  return {
    debug: (ctx: Context, msg: string) => log("debug", ctx, msg),
    info: (ctx: Context, msg: string) => log("info", ctx, msg),
    warn: (ctx: Context, msg: string) => log("warn", ctx, msg),
    error: (ctx: Error | Context, msg: string) => {
      let context: Context;
      if (ctx instanceof Error) {
        context = { err: { message: ctx.message, stack: ctx.stack, name: ctx.name } };
      } else {
        context = { ...ctx };
        // If the context contains an error object, format it for better visibility
        const rawErr = (ctx as any).error || (ctx as any).err;
        if (rawErr instanceof Error) {
          context.err = { 
            message: rawErr.message, 
            stack: rawErr.stack, 
            name: rawErr.name 
          };
          // Remove the raw error object to prevent serialization/crash issues in some environments
          delete (context as any).error;
          delete (context as any).err;
        }
      }
      log("error", context, msg);
    },
  };
}
