export function RepealedStamp() {
  return (
    <svg viewBox="0 0 120 120" className="stamp-svg" aria-hidden="true">
      <circle
        cx="60"
        cy="60"
        r="52"
        fill="none"
        stroke="var(--stamp-crimson)"
        strokeWidth="3"
        strokeDasharray="6 4"
      />
      <text
        x="60"
        y="55"
        textAnchor="middle"
        fontFamily="var(--font-mono)"
        fontSize="12"
        letterSpacing="2"
        fill="var(--stamp-crimson)"
      >
        REPEALED
      </text>
      <text
        x="60"
        y="72"
        textAnchor="middle"
        fontFamily="var(--font-mono)"
        fontSize="9"
        letterSpacing="3"
        fill="var(--stamp-crimson)"
      >
        1 JUL 2024
      </text>
    </svg>
  );
}

export function InForceSeal() {
  return (
    <svg viewBox="0 0 120 120" className="seal-svg" aria-hidden="true">
      <circle cx="60" cy="60" r="54" fill="none" stroke="var(--seal-gold)" strokeWidth="1.5" />
      <circle cx="60" cy="60" r="46" fill="none" stroke="var(--seal-gold)" strokeWidth="2.5" />
      <text
        x="60"
        y="56"
        textAnchor="middle"
        fontFamily="var(--font-mono)"
        fontSize="11"
        letterSpacing="2"
        fill="var(--seal-gold)"
      >
        IN FORCE
      </text>
      <text
        x="60"
        y="73"
        textAnchor="middle"
        fontFamily="var(--font-mono)"
        fontSize="9"
        letterSpacing="3"
        fill="var(--seal-gold)"
      >
        CURRENT LAW
      </text>
    </svg>
  );
}
