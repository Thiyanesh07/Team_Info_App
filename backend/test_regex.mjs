import { Client } from "@gradio/client";

async function testHFRegex() {
    try {
        console.log("🚀 Connecting to Hugging Face Space: PraneshJs/RewardPointsSite...");
        const client = await Client.connect("PraneshJs/RewardPointsSite");
        
        const rollNo = "7376242AD328";
        console.log(`📡 Searching for student: ${rollNo}...`);
        
        const result = await client.predict("/search_student", { 		
            roll_no: rollNo, 
        });

        const report = result.data[0];
        console.log("--- RAW REPORT START ---");
        console.log(report);
        console.log("--- RAW REPORT END ---");

        const balanceMatch = report.match(/BALANCE POINTS\s*:\s*([\d,.]+)/);
        const cumulativeMatch = report.match(/CUMULATIVE REWARD POINTS\s*:\s*([\d,.]+)/);
        const averageMatch = report.match(/Average Points for (Year [IV]+)\s*:\s*(\d+)/);
        const yearMatch = report.match(/YEAR\s*:\s*([IV]+)/);

        console.log("\n--- REGEX MATCH RESULTS ---");
        console.log("Balance Match:", balanceMatch ? balanceMatch[1] : "FAILED");
        console.log("Cumulative Match:", cumulativeMatch ? cumulativeMatch[1] : "FAILED");
        console.log("Average Match:", averageMatch ? `${averageMatch[1]}: ${averageMatch[2]}` : "FAILED");
        console.log("Year Match:", yearMatch ? yearMatch[1] : "FAILED");

        if (balanceMatch) {
            const points = parseFloat(balanceMatch[1].replace(/,/g, ''));
            console.log("Parsed Points:", points);
        }

    } catch (error) {
        console.error("❌ Error:", error.message);
    }
}

testHFRegex();
