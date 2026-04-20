TOOLKIT = [

    #  Breathing 
    {
        "id": "breathing_box",
        "category": "breathing",
        "title": "Box Breathing",
        "description": "A simple 4-4-4-4 technique to calm your nervous system.",
        "icon": "air",
        "steps": [
            {"step": 1, "instruction": "Inhale slowly through your nose", "duration_seconds": 4},
            {"step": 2, "instruction": "Hold your breath", "duration_seconds": 4},
            {"step": 3, "instruction": "Exhale slowly through your mouth", "duration_seconds": 4},
            {"step": 4, "instruction": "Hold again before next breath", "duration_seconds": 4},
        ],
        "repeat": 4,
        "tip": "Used by Navy SEALs to manage stress in high-pressure situations.",
    },
    {
        "id": "breathing_478",
        "category": "breathing",
        "title": "4-7-8 Breathing",
        "description": "Activates your parasympathetic nervous system to reduce anxiety fast.",
        "icon": "air",
        "steps": [
            {"step": 1, "instruction": "Inhale quietly through your nose", "duration_seconds": 4},
            {"step": 2, "instruction": "Hold your breath", "duration_seconds": 7},
            {"step": 3, "instruction": "Exhale completely through your mouth", "duration_seconds": 8},
        ],
        "repeat": 3,
        "tip": "Dr. Andrew Weil calls this a natural tranquilizer for the nervous system.",
    },

    #  Grounding 
    {
        "id": "grounding_54321",
        "category": "grounding",
        "title": "5-4-3-2-1 Grounding",
        "description": "Bring yourself back to the present moment using your five senses.",
        "icon": "anchor",
        "steps": [
            {"step": 1, "sense": "👁 See", "instruction": "Name 5 things you can see right now"},
            {"step": 2, "sense": "✋ Touch", "instruction": "Name 4 things you can physically feel"},
            {"step": 3, "sense": "👂 Hear", "instruction": "Name 3 things you can hear"},
            {"step": 4, "sense": "👃 Smell", "instruction": "Name 2 things you can smell"},
            {"step": 5, "sense": "👅 Taste", "instruction": "Name 1 thing you can taste"},
        ],
        "tip": "Best used during anxiety attacks or dissociative moments.",
    },
    {
        "id": "grounding_body_scan",
        "category": "grounding",
        "title": "Body Scan",
        "description": "Scan through your body from head to toe to release tension.",
        "icon": "accessibility",
        "steps": [
            {"step": 1, "instruction": "Close your eyes and take 3 deep breaths"},
            {"step": 2, "instruction": "Notice any tension in your head and face — let it soften"},
            {"step": 3, "instruction": "Move to your neck and shoulders — drop them away from your ears"},
            {"step": 4, "instruction": "Scan your chest and belly — let your breath be natural"},
            {"step": 5, "instruction": "Move to your arms, hands, fingers — unclench"},
            {"step": 6, "instruction": "Scan your hips, legs, feet — feel the ground beneath you"},
            {"step": 7, "instruction": "Take one final deep breath and open your eyes slowly"},
        ],
        "tip": "Practice daily before sleep to improve sleep quality.",
    },

    #  Motivational Quotes 
    {
        "id": "quotes_daily",
        "category": "quotes",
        "title": "Daily Motivation",
        "description": "A curated set of quotes to shift your perspective.",
        "icon": "format_quote",
        "quotes": [
            {"text": "You don't have to be positive all the time. It's perfectly okay to feel sad, angry, annoyed, frustrated, scared, or anxious.", "author": "Lori Deschene"},
            {"text": "There is hope, even when your brain tells you there isn't.", "author": "John Green"},
            {"text": "You are allowed to be both a masterpiece and a work in progress simultaneously.", "author": "Sophia Bush"},
            {"text": "Self-care is not selfish. You cannot serve from an empty vessel.", "author": "Eleanor Brown"},
            {"text": "It's okay to not be okay — as long as you are not giving up.", "author": "Karen Salmansohn"},
            {"text": "What mental health needs is more sunlight, more candor, and more unashamed conversation.", "author": "Glenn Close"},
            {"text": "You are stronger than you think, braver than you feel, and more loved than you know.", "author": "Unknown"},
            {"text": "Healing is not linear.", "author": "Unknown"},
            {"text": "Recovery is not one and done. It is a lifelong journey that takes place one day, one step at a time.", "author": "Unknown"},
            {"text": "Be gentle with yourself. You are a child of the universe, no less than the trees and the stars.", "author": "Max Ehrmann"},
        ],
    },

    #  CBT Toolkit 
    {
        "id": "cbt_cognitive_distortions",
        "category": "cbt",
        "title": "Cognitive Distortions",
        "description": "Identify thinking traps that fuel anxiety and depression.",
        "icon": "psychology",
        "distortions": [
            {"name": "All-or-Nothing Thinking", "description": "Seeing things in black and white with no middle ground.", "example": "If I'm not perfect, I'm a total failure."},
            {"name": "Overgeneralisation", "description": "Drawing broad conclusions from a single event.", "example": "This always happens to me. Nothing ever works out."},
            {"name": "Mental Filter", "description": "Focusing only on negatives while ignoring positives.", "example": "I got great feedback but one criticism ruins everything."},
            {"name": "Discounting the Positive", "description": "Dismissing good things as if they don't count.", "example": "I only did well because it was easy."},
            {"name": "Mind Reading", "description": "Assuming you know what others are thinking.", "example": "They didn't reply — they must be angry with me."},
            {"name": "Fortune Telling", "description": "Predicting the future will be negative.", "example": "I know I'm going to fail this exam."},
            {"name": "Catastrophising", "description": "Blowing things out of proportion.", "example": "If I make a mistake at work, I'll be fired and ruin my life."},
            {"name": "Emotional Reasoning", "description": "Believing something is true because it feels true.", "example": "I feel stupid, so I must be stupid."},
            {"name": "Should Statements", "description": "Rigid rules about how you or others must behave.", "example": "I should always be productive. I shouldn't need help."},
            {"name": "Labelling", "description": "Attaching a negative label to yourself or others.", "example": "I'm a loser. He's an idiot."},
            {"name": "Personalisation", "description": "Blaming yourself for things outside your control.", "example": "My friend seems sad — it must be something I did."},
        ],
    },
    {
        "id": "cbt_thought_record",
        "category": "cbt",
        "title": "Thought Record",
        "description": "Challenge and reframe negative automatic thoughts using CBT.",
        "icon": "edit_note",
        "template": [
            {"field": "situation", "label": "Situation", "prompt": "What happened? Where were you? Who was there?"},
            {"field": "automatic_thought", "label": "Automatic Thought", "prompt": "What went through your mind? What did you tell yourself?"},
            {"field": "emotion", "label": "Emotion", "prompt": "What emotions did you feel? Rate intensity 0–100."},
            {"field": "evidence_for", "label": "Evidence FOR the thought", "prompt": "What facts support this thought?"},
            {"field": "evidence_against", "label": "Evidence AGAINST the thought", "prompt": "What facts contradict this thought?"},
            {"field": "balanced_thought", "label": "Balanced Thought", "prompt": "Write a more balanced, realistic version of your thought."},
            {"field": "outcome_emotion", "label": "Emotion After", "prompt": "How do you feel now? Rate intensity 0–100."},
        ],
        "tip": "Use this whenever you notice a strong negative emotion pulling you down.",
    },
    {
        "id": "cbt_behavioral_activation",
        "category": "cbt",
        "title": "Behavioural Activation Planner",
        "description": "Break the cycle of low mood and inactivity by scheduling meaningful activities.",
        "icon": "event_available",
        "explanation": "Depression often creates a vicious cycle: low mood → less activity → less pleasure → lower mood. Behavioural activation interrupts this by deliberately scheduling activities that give you a sense of mastery or pleasure.",
        "activity_categories": [
            {"category": "Pleasure", "examples": ["Watch a favourite show", "Take a warm bath", "Listen to music", "Cook something you enjoy"]},
            {"category": "Mastery", "examples": ["Clean one room", "Reply to a pending email", "Learn something new for 10 mins", "Finish a small task"]},
            {"category": "Social", "examples": ["Text a friend", "Call a family member", "Join an online community", "Smile at a stranger"]},
            {"category": "Physical", "examples": ["Walk for 10 minutes", "Stretch for 5 minutes", "Dance to one song", "Drink a full glass of water"]},
        ],
        "planner_template": [
            {"time": "Morning", "activity": "", "type": "", "mood_before": "", "mood_after": ""},
            {"time": "Afternoon", "activity": "", "type": "", "mood_before": "", "mood_after": ""},
            {"time": "Evening", "activity": "", "type": "", "mood_before": "", "mood_after": ""},
        ],
        "tip": "Start small — even a 5 minute walk counts. The goal is momentum, not perfection.",
    },

    #  DBT Toolkit 
    {
        "id": "dbt_tipp",
        "category": "dbt",
        "title": "TIPP — Distress Tolerance",
        "description": "Rapidly reduce overwhelming emotional distress using body-based skills.",
        "icon": "thermostat",
        "explanation": "TIPP targets your body's physiology to bring intense emotions down quickly. Based on Marsha Linehan's DBT.",
        "skills": [
            {
                "letter": "T",
                "skill": "Temperature",
                "description": "Change your body temperature to interrupt emotional escalation.",
                "how_to": [
                    "Splash cold water on your face for 30 seconds",
                    "Hold an ice cube in your hand",
                    "Step outside into cold air",
                    "Drink a cold glass of water slowly",
                ]
            },
            {
                "letter": "I",
                "skill": "Intense Exercise",
                "description": "Burn off the adrenaline fuelling your distress.",
                "how_to": [
                    "Do 20 jumping jacks",
                    "Run in place for 1 minute",
                    "Do 10 push-ups",
                    "Dance intensely to one song",
                ]
            },
            {
                "letter": "P",
                "skill": "Paced Breathing",
                "description": "Slow your exhale to activate the parasympathetic nervous system.",
                "how_to": [
                    "Inhale for 4 counts",
                    "Exhale slowly for 6–8 counts",
                    "Repeat for 2–3 minutes",
                ]
            },
            {
                "letter": "P",
                "skill": "Progressive Muscle Relaxation",
                "description": "Tense and release muscle groups to release physical tension.",
                "how_to": [
                    "Tense your feet — hold 5 seconds — release",
                    "Tense your calves — hold 5 seconds — release",
                    "Tense your thighs — hold 5 seconds — release",
                    "Tense your stomach — hold 5 seconds — release",
                    "Tense your hands into fists — hold — release",
                    "Tense your shoulders up to ears — hold — release",
                    "Scrunch your face — hold — release",
                ]
            },
        ],
    },
    {
        "id": "dbt_emotion_regulation",
        "category": "dbt",
        "title": "Emotion Regulation Map",
        "description": "Understand and name your emotions to reduce their power over you.",
        "icon": "map",
        "explanation": "Naming an emotion activates the prefrontal cortex and reduces amygdala reactivity — literally calming your brain.",
        "steps": [
            {"step": 1, "instruction": "Name the emotion — what exactly are you feeling? Be specific (not just 'bad')"},
            {"step": 2, "instruction": "Rate its intensity from 0 (barely there) to 10 (overwhelming)"},
            {"step": 3, "instruction": "Identify the trigger — what event or thought sparked this feeling?"},
            {"step": 4, "instruction": "Notice body sensations — where do you feel it physically?"},
            {"step": 5, "instruction": "Check the facts — is the emotion proportionate to the situation?"},
            {"step": 6, "instruction": "Choose a response — act opposite to urge, or ride the wave without acting"},
        ],
        "emotion_wheel": [
            {"primary": "Sad", "secondary": ["Lonely", "Grief", "Hopeless", "Disappointed", "Powerless"]},
            {"primary": "Angry", "secondary": ["Frustrated", "Irritated", "Resentful", "Jealous", "Disgusted"]},
            {"primary": "Fearful", "secondary": ["Anxious", "Insecure", "Overwhelmed", "Panicked", "Worried"]},
            {"primary": "Surprised", "secondary": ["Confused", "Shocked", "Amazed", "Unsettled"]},
            {"primary": "Happy", "secondary": ["Grateful", "Hopeful", "Proud", "Content", "Excited"]},
        ],
    },
    {
        "id": "dbt_interpersonal",
        "category": "dbt",
        "title": "Interpersonal Effectiveness",
        "description": "Scripts to help you set boundaries, make requests, and maintain relationships.",
        "icon": "people",
        "skills": [
            {
                "name": "DEAR MAN — Making Requests",
                "steps": [
                    {"letter": "D", "skill": "Describe", "example": "State the facts without judgment: 'When you cancel plans last minute...'"},
                    {"letter": "E", "skill": "Express", "example": "Share your feeling using I-statements: 'I feel hurt and unimportant...'"},
                    {"letter": "A", "skill": "Assert", "example": "Ask clearly for what you want: 'I'd like you to let me know earlier...'"},
                    {"letter": "R", "skill": "Reinforce", "example": "Explain the benefit: 'That way I can make other plans and won't feel let down.'"},
                    {"letter": "M", "skill": "Mindful", "example": "Stay focused on your goal, don't get sidetracked by other issues"},
                    {"letter": "A", "skill": "Appear Confident", "example": "Maintain eye contact, speak calmly, don't apologise for having needs"},
                    {"letter": "N", "skill": "Negotiate", "example": "Be willing to give a little: 'What works better for you?'"},
                ]
            },
            {
                "name": "FAST — Keeping Self-Respect",
                "steps": [
                    {"letter": "F", "skill": "Fair", "example": "Be fair to yourself AND the other person"},
                    {"letter": "A", "skill": "No Apologies", "example": "Don't apologise for having needs or opinions"},
                    {"letter": "S", "skill": "Stick to Values", "example": "Don't compromise your values to please others"},
                    {"letter": "T", "skill": "Truthful", "example": "Don't lie, exaggerate, or act helpless"},
                ]
            },
        ],
    },
    {
        "id": "dbt_radical_acceptance",
        "category": "dbt",
        "title": "Radical Acceptance",
        "description": "Accept reality as it is — not as you wish it were — to reduce suffering.",
        "icon": "self_improvement",
        "explanation": "Pain is inevitable. Suffering is optional. Radical acceptance means fully accepting facts without fighting, judging, or wishing them away. It does NOT mean approving of or liking what happened.",
        "steps": [
            {"step": 1, "instruction": "Observe that you are fighting or resisting reality — notice the tension"},
            {"step": 2, "instruction": "Remind yourself: 'This is what happened. I cannot change the past.'"},
            {"step": 3, "instruction": "Consider the causes — every event has causes. This doesn't mean it's your fault or it's okay."},
            {"step": 4, "instruction": "Practice acceptance with your body — relax your jaw, unclench your fists, soften your posture"},
            {"step": 5, "instruction": "Cope ahead — what can you do NOW, given that this is your reality?"},
            {"step": 6, "instruction": "Repeat the acceptance statement: 'It is what it is. I can bear this. I will find a way forward.'"},
        ],
        "common_resistances": [
            "Accepting means I approve of what happened",
            "If I accept it, I have to stop trying to change things",
            "I don't deserve to accept this — it was my fault",
        ],
        "rebuttals": [
            "Acceptance is about seeing clearly, not endorsing",
            "You can accept AND work toward change",
            "Acceptance is for your peace, not as a judgment of blame",
        ],
    },

    #  Self-Compassion Toolkit 
    {
        "id": "sc_inner_critic",
        "category": "self_compassion",
        "title": "Inner Critic Dialogue",
        "description": "Identify your inner critic's voice and respond with kindness.",
        "icon": "record_voice_over",
        "explanation": "Your inner critic developed to protect you — but often it goes too far. This exercise helps you hear it clearly and respond like a wise, caring friend would.",
        "steps": [
            {"step": 1, "instruction": "Write down exactly what your inner critic is saying right now (don't censor it)"},
            {"step": 2, "instruction": "Read it back — would you say this to someone you love who was struggling?"},
            {"step": 3, "instruction": "Now write what a kind, wise friend would say to you about the same situation"},
            {"step": 4, "instruction": "Notice the difference in tone — this is the voice of self-compassion"},
            {"step": 5, "instruction": "Rewrite the critic's message in the kinder voice"},
        ],
        "example": {
            "critic": "I'm so stupid. I always mess things up. Nobody will ever trust me.",
            "compassionate_response": "You made a mistake — that's human. You're being really hard on yourself right now. What can you learn from this? You've recovered from hard things before.",
        },
    },
    {
        "id": "sc_self_kindness_scripts",
        "category": "self_compassion",
        "title": "Self-Kindness Scripts",
        "description": "Words to offer yourself in moments of pain, failure, or shame.",
        "icon": "favorite",
        "scripts": [
            {"moment": "After a mistake", "script": "This is a moment of suffering. Suffering is part of life. May I be kind to myself right now. May I give myself the compassion I need."},
            {"moment": "Feeling overwhelmed", "script": "It's okay to feel this way. I don't have to have it all together. I am doing the best I can with what I have right now."},
            {"moment": "Comparing yourself to others", "script": "My journey is my own. I am exactly where I need to be. My worth is not measured by comparison."},
            {"moment": "Feeling like a burden", "script": "My needs are valid. Asking for help is brave, not weak. I deserve care and support just as much as anyone else."},
            {"moment": "After a setback", "script": "Setbacks are not the end. They are part of every story worth telling. I will rest, and then I will try again."},
            {"moment": "Loneliness", "script": "Many people feel exactly what I'm feeling right now. I am not alone in this. I can reach out, or I can sit with this gently."},
        ],
    },
    {
        "id": "sc_shame_processing",
        "category": "self_compassion",
        "title": "Shame Processing Exercise",
        "description": "Move through shame without letting it define you.",
        "icon": "healing",
        "explanation": "Shame says 'I am bad.' Guilt says 'I did something bad.' Shame thrives in silence and isolation — it dissolves when met with empathy.",
        "steps": [
            {"step": 1, "instruction": "Name it: Write down what you feel ashamed about. Be specific."},
            {"step": 2, "instruction": "Locate it: Where do you feel shame in your body? Chest tightening? Face flushing? Stomach dropping?"},
            {"step": 3, "instruction": "Contextualise it: What factors (environment, past experiences, pressures) contributed to this?"},
            {"step": 4, "instruction": "Humanise it: Write one sentence starting with 'Most humans in my situation would...'"},
            {"step": 5, "instruction": "Separate it: 'This is something I did or felt — it is NOT who I am'"},
            {"step": 6, "instruction": "Respond with empathy: What would you say to a friend sharing this shame with you?"},
        ],
        "affirmations": [
            "I am more than my worst moments.",
            "Shame is not the truth of who I am.",
            "I am worthy of love and belonging, even now.",
            "I can acknowledge what happened and still treat myself with dignity.",
        ],
    },
]