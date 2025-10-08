use anyhow::Result;
use serde::{Deserialize, Serialize};
use std::io::{self, Read};

#[derive(Debug, Deserialize)]
struct InputPayload {
    message: Option<String>,
    ping: Option<bool>,
    timestamp: Option<String>,
}

#[derive(Debug, Serialize)]
struct OutputPayload {
    ok: bool,
    input: serde_json::Value,
    response: Option<String>,
    pong: Option<bool>,
}

fn main() -> Result<()> {
    let mut buffer = String::new();
    io::stdin().read_to_string(&mut buffer)?;

    let value: serde_json::Value = if buffer.trim().is_empty() {
        serde_json::json!({})
    } else {
        serde_json::from_str(&buffer)?
    };

    // Parse the input to check for ping
    let input_payload: InputPayload = serde_json::from_value(value.clone())?;
    
    let mut output = OutputPayload {
        ok: true,
        input: value,
        response: None,
        pong: None,
    };

    // Handle ping requests
    if input_payload.ping == Some(true) {
        output.pong = Some(true);
        output.response = Some(format!("Pong! Rust binary is alive. Received at: {}", 
            input_payload.timestamp.unwrap_or_else(|| "unknown".to_string())));
    } else if let Some(message) = input_payload.message {
        output.response = Some(format!("Echo: {}", message));
    } else {
        output.response = Some("No specific message provided".to_string());
    }

    let json = serde_json::to_string(&output)?;
    println!("{}", json);
    Ok(())
}