import neo4j, { Driver } from "neo4j-driver";

const { NEO4J_URI, NEO4J_USER, NEO4J_PASSWORD } = process.env;

if (!NEO4J_URI || !NEO4J_USER || !NEO4J_PASSWORD) {
  throw new Error("NEO4J_URI / NEO4J_USER / NEO4J_PASSWORD are not configured");
}

const globalForNeo4j = globalThis as unknown as { neo4jDriver?: Driver };

export const driver =
  globalForNeo4j.neo4jDriver ??
  neo4j.driver(NEO4J_URI, neo4j.auth.basic(NEO4J_USER, NEO4J_PASSWORD), {
    disableLosslessIntegers: true, // return plain JS numbers
  });

if (process.env.NODE_ENV !== "production") {
  globalForNeo4j.neo4jDriver = driver;
}
