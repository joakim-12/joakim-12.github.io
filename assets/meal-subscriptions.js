import { s as supabase } from "./supabase-BZASSCr-.js";

const el = (id) => document.getElementById(id);
const form = el("meal-subscription-form");
const planSelect = el("meal-subscription-plan");
const schoolInput = el("school-input");
const status = el("meal-subscription-status");
const mineBox = el("meal-subscription-list");
const officeBox = el("meal-subscription-office-list");
let school = "";

function say(text, error = false) {
    status.textContent = text;
    status.classList.toggle("error", error);
    status.classList.toggle("success", !!text && !error);
}

function key(text) {
    return String(text || "").trim().toLowerCase().replace(/\s+/g, " ");
}

function card(titleText, detailText) {
    const node = document.createElement("article");
    node.className = "uni-card";
    const title = document.createElement("strong");
    title.textContent = String(titleText || "");
    const detail = document.createElement("p");
    detail.className = "uni-meta";
    detail.textContent = String(detailText || "");
    node.append(title, detail);
    return node;
}

async function refresh() {
    const { data: auth } = await supabase.auth.getUser();
    school = String(schoolInput.value || school).trim();
    if (!auth?.user || !school) return;
    const schoolKey = key(school);
    const { data: plans, error: planError } = await supabase
        .from("meal_plans")
        .select("id,name,kind,price_semester")
        .eq("school_key", schoolKey)
        .order("created_at", { ascending: false });
    if (planError) return say("Meal plans could not be loaded. Refresh the page and try again.", true);
    planSelect.replaceChildren();
    for (const plan of plans || []) {
        const option = document.createElement("option");
        option.value = plan.id;
        const meals = plan.kind === "full" ? "three meals a day"
            : plan.kind === "half" ? "two meals a day" : plan.kind;
        const price = plan.price_semester == null ? "price set by catering office"
            : `KES ${Number(plan.price_semester).toLocaleString("en-KE")} per semester`;
        option.textContent = `${plan.name} · ${meals} · ${price}`;
        planSelect.append(option);
    }
    const { data: mine, error: mineError } = await supabase.rpc("my_meal_subscriptions_v1");
    mineBox.replaceChildren();
    if (mineError) say("Your meal-plan requests could not be loaded.", true);
    else if (!mine?.length) mineBox.textContent = "No meal-plan requests yet.";
    else for (const row of mine) {
        mineBox.append(card(row.plan_name, `${row.semester} · ${row.status}${row.ends_at ? ` · ends ${new Date(row.ends_at).toLocaleDateString()}` : ""}`));
    }
    const { data: office, error: officeError } = await supabase.rpc("school_meal_subscriptions_v1", {
        p_school_key: schoolKey
    });
    officeBox.replaceChildren();
    if (officeError) return;
    if (!office?.length) officeBox.textContent = "No meal-plan requests are waiting.";
    for (const row of office || []) {
        const node = card(`${row.student_name} · ${row.plan_name}`, `${row.registration_number || "No registration number"} · ${row.semester} · ${row.status}`);
        if (row.status === "requested") for (const [approve, label] of [[true, "Approve subscription"], [false, "Decline"]]) {
            const button = document.createElement("button");
            button.type = "button";
            button.textContent = label;
            button.addEventListener("click", async () => {
                button.disabled = true;
                const { error } = await supabase.rpc("review_meal_subscription_v1", {
                    p_subscription_id: row.subscription_id, p_approve: approve, p_note: ""
                });
                if (error) say(error.message || "The decision could not be saved.", true);
                else { say("The meal-plan request was updated."); await refresh(); }
                button.disabled = false;
            });
            node.append(button);
        }
        officeBox.append(node);
    }
}

form.addEventListener("submit", async (event) => {
    event.preventDefault();
    const button = form.querySelector("button[type=submit]");
    if (!planSelect.value) return say("Choose a meal plan first.", true);
    button.disabled = true;
    say("Sending your request…");
    const { error } = await supabase.rpc("request_meal_subscription_v1", {
        p_meal_plan_id: planSelect.value,
        p_semester: el("meal-subscription-semester").value.trim()
    });
    if (error) say(error.message || "The request could not be sent.", true);
    else { say("Your request was sent to the catering office."); await refresh(); }
    button.disabled = false;
});

el("school-go").addEventListener("click", () => window.setTimeout(refresh, 300));
schoolInput.addEventListener("keydown", (event) => {
    if (event.key === "Enter") window.setTimeout(refresh, 300);
});
supabase.auth.onAuthStateChange(() => window.setTimeout(refresh, 0));
window.addEventListener("campus:services-ready", (event) => {
    if (event.detail?.school) school = event.detail.school;
    void refresh();
});
window.setTimeout(refresh, 1200);

