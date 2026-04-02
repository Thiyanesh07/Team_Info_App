import { Client } from "@gradio/client";

async function testHF() {
    try {
        console.log("🚀 Connecting to Hugging Face Space: PraneshJs/RewardPointsSite...");
        const client = await Client.connect("PraneshJs/RewardPointsSite");
        
        const rollNo = "7376242AD328";
        console.log(`📡 Searching for student: ${rollNo}...`);
        
        const result = await client.predict("/search_student", { 		
            roll_no: rollNo, 
        });

        console.log("✅ Success! Raw Data:");
        console.log(JSON.stringify(result.data, null, 2));
    } catch (error) {
        console.error("❌ Error connecting to HF API:", error.message);
    }
}

testHF();
