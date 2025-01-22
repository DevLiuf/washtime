// Node.js 스크립트 예시
const { createClient } = require("@supabase/supabase-js");

const supabase = createClient(
  "https://mrbpenlhhfclyskhbmgx.supabase.co",
  "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1yYnBlbmxoaGZjbHlza2hibWd4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mzc1MTAyMTQsImV4cCI6MjA1MzA4NjIxNH0.ypM1AroBYRs84mEbHKNiuUAqTMVLd2F8BH1UJ3l7Mps"
);

async function decrementTime() {
  const { data, error } = await supabase
    .from("devices")
    .select("*")
    .eq("status", "inUse");

  if (error) {
    console.error("Error fetching devices:", error);
    return;
  }

  data.forEach(async (device) => {
    if (device.remainingTime > 0) {
      const newTime = device.remainingTime - 1;
      const { error } = await supabase
        .from("devices")
        .update({ remainingTime: newTime })
        .eq("id", device.id);

      if (error) {
        console.error(`Failed to update device ${device.id}:`, error);
      }
    }
  });
}

// 주기적 실행을 위한 코드 (예: setInterval 사용)
setInterval(decrementTime, 1000); // 1초마다 실행
