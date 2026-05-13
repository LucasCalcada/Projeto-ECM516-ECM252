export default function log(context: string, message: string) {
  const currentTimeString = new Date().toISOString();
  console.log(`[${context}] - ${currentTimeString} - ${message}`);
}
