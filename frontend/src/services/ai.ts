import { GoogleGenerativeAI } from "@google/generative-ai";
import { Expense } from "../api/expenses";

const API_KEY = import.meta.env.VITE_GEMINI_API_KEY;

let genAI: GoogleGenerativeAI | null = null;
let model: any = null;

if (API_KEY) {
    genAI = new GoogleGenerativeAI(API_KEY);
    model = genAI.getGenerativeModel({ model: "gemini-2.5-flash" });
}

export const isAIEnabled = () => !!API_KEY;

export const suggestCategory = async (description: string): Promise<string | null> => {
    if (!model) return null;

    const categories = [
        "Food & Drink", "Transportation", "Shopping", "Entertainment",
        "Groceries", "Utilities", "Housing", "Healthcare", "Travel", "Personal Care", "Education", "Other"
    ];

    const prompt = `
        You are an expense categorization assistant.
        Task: Categorize the following expense description into EXACTLY ONE of these categories: ${categories.join(", ")}.
        Description: "${description}"
        
        Rules:
        1. Return ONLY the category name.
        2. If it doesn't fit well, return "Other".
        3. Do not add any explanation or punctuation.
    `;

    try {
        const result = await model.generateContent(prompt);
        const response = result.response;
        const text = response.text().trim();

        
        if (categories.includes(text)) {
            return text;
        }
        return "Other";
    } catch (error) {
        console.error("Error suggesting category:", error);
        return null;
    }
};

export const generateInsights = async (expenses: Expense[]): Promise<string[]> => {
    if (!model || expenses.length === 0) return [];

    
    const expenseSummary = expenses.slice(0, 50).map(e => `${e.date}: ${e.description} ($${e.amount}) - ${e.category}`).join("\n");
    const totalAmount = expenses.reduce((sum, e) => sum + e.amount, 0);

    const prompt = `
        You are a financial advisor. Analyze the following recent expenses (Total: $${totalAmount}):
        
        ${expenseSummary}
        
        Task: Provide 3 short, actionable insights or observations about the spending habits.
        Rules:
        1. Each insight should be one sentence.
        2. Focus on spending trends, high-value categories, or potential savings.
        3. Be encouraging but realistic.
        4. Return the result as a JSON array of strings, e.g., ["Insight 1", "Insight 2", "Insight 3"].
        5. Do not include markdown formatting like \`\`\`json.
    `;

    try {
        const result = await model.generateContent(prompt);
        const response = result.response;
        const text = response.text().trim();

        
        const cleanText = text.replace(/```json/g, "").replace(/```/g, "").trim();

        return JSON.parse(cleanText);
    } catch (error) {
        console.error("Error generating insights:", error);
        return ["Unable to generate insights at this time."];
    }
};
