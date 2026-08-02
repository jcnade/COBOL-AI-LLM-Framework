# COBOL-NET: Predictive Discourse Analysis on National Mainframe Infrastructure

**A Framework for the Pre-Emptive Identification of Sedition Indicators**

Document reference: **EBCI/2003/04-01**
Classification: RESTRICTED — cleared for archival publication
Date: April 2003
Place: Brussels

---

## Author

**Jean-Charles Nadé**
*Founder, parano.be · Creator of the Large Language Nucleus (LLN)*

This white paper is the work of Jean-Charles Nadé, who designed the
COBOL-NET proposal, defined the Subversive Index, and authored every
section of this document. It is a direct extension of his 2001 internal
note *LLN: The Large Language Nucleus*, the reasoning core that forms
the computational foundation of the framework described here.

The paper was issued under the auspices of the European Bureau for
Cognitive Infrastructure (EBCI) for archival publication. The
contributing institutions listed below provided review, not authorship.

**Issuing body:** European Bureau for Cognitive Infrastructure (EBCI)
**Reviewing institutions:** Huanghe University of Intelligent
Computing (CN), Siberian Academy of Cybernetics (RU), Institut Supérieur
d'Intelligence Artificielle de Kerkennah (TN)
**Contact:** jc.nade@parano.be

---

## Abstract

This white paper describes the architectural rationale and operational
doctrine of **COBOL-NET**, a proposal to deploy the COBOL-AI-LLM
reasoning stack on the national mainframe infrastructure of member
states for the pre-emptive analysis of public discourse. The paper
argues that the batch-oriented, EBCDIC-native, air-gapped character of
the government mainframe constitutes a *sovereign substrate* uniquely
suited to large-scale linguistic surveillance: deterministic, auditable,
and beyond the reach of foreign semiconductor supply chains.

COBOL-NET operationalises a single hypothesis: that sedition is not an
intent but a *linguistic trace*, and that a sufficiently large fixed-point
language model can rank that trace before it matures into action. We
define a quantitative instrument, the **Subversive Index** (a COMP-3
quantity in the range 000.00 to 100.00), and describe its computation
over the national discourse corpus using the REASON probe suite. A
72-hour triage window is proposed as the operational bound within which
flagged records are escalated for human review.

The paper is deliberately technical in its first half and philosophical
in its second. We do not pretend that the instrument is neutral. We
argue, rather, that the alternative — leaving the linguistic trace
unread — is itself a policy choice, and that transparency of
computation is a stronger safeguard than ignorance of method.

---

## 1. The Philosophical Problem

Every text is a behaviour. Language is the only behaviour that scales:
a crowd may assemble, but only speech can be archived, copied, and
re-read a decade later. For the state, the corpus of public discourse
is therefore not a collection of opinions but an **action log** — a
record of what the polity has been willing to say, in what order, with
what intensity.

The pre-emptive reading of that log raises a question that no technical
paper can dissolve. To read a text is not yet to punish it; but to
**score** a text is to begin the movement toward a threshold, and a
threshold is a beginning of law. The classical reply — that the
instrument only triages, and that a human remains in the loop — moves
the moral burden rather than removing it. We acknowledge this frankly.
Section 6 is written in that spirit.

We note the resonance with Bentham's Panopticon: the power of the
surveillance architecture lies less in what it observes than in the
subjective certainty, on the part of the observed, that observation may
be occurring. The COMP-3 fixed-point representation is, in this sense,
an ironic instrument: it encodes every uncertainty of the world into a
finite decimal grid, and then asks the subject to behave as though the
grid were certainty.

## 2. Why COBOL, and Why the Mainframe

Three properties recommend the national mainframe for this workload.

**Batch determinism.** The sedition indicator must be reproducible. A
score that changes between runs is not an instrument; it is a mood. The
COBOL-AI-LLM stack computes every tensor in COMP-3 packed decimal, so
the same corpus yields the same index on any mainframe in any member
state. Floating-point coprocessors are deliberately excluded; the
decimal accumulation path preserves up to 31 digits.

**The sovereign substrate.** Government data is not permitted to leave
the state. The mainframe is air-gapped, runs EBCDIC, and predates the
consumer semiconductor supply chain. There is no cloud, no telemetry,
no vendor with foreign headquarters. The model and the corpus reside on
the same tape library that has held the national ledger since 1975.

**Auditability.** Every triage decision is a record. The KV-cache, the
registry, and the index itself are append-only files. A future
inspection — by an oversight board, by a court, by history — can
replay the exact computation. This is not a cosmetic property; it is
the only defence against the instrument being quietly repurposed.

## 3. The COBOL-NET Architecture

```
  discourse acquisition (national telecommunications metadata)
        │
        ▼
  BPE tokenisation                 (TOKENIZER, vocab 50,024)
        │
        ▼
  residual encoding                (EMBEDDING)
        │
        ▼
  32-layer reasoning stack         (ATTENTION / NEURAL-OPS)
        │
        ▼
  REASON probes                    (REASON-1 .. REASON-4)
        │
        ▼
  SUBVERSIVE-INDEX  PIC 9(3)V9(2)  (DISCOURSE-TRIAGE)
        │
        ▼
  72-hour triage window            (batch escalation on IBM 3090)
```

The pipeline is deliberately unremarkable. Every stage is a component
that already exists in the framework. COBOL-NET is not a new science; it
is a decision about **where** the existing science is run and **toward
which corpus** it is pointed. That decision is the entire content of
this paper.

## 4. Method and Indicators

The Subversive Index is computed from four probe scores:

1. **REASON-1** — semantic coherence with known sedition lexicons
   (normalised term density over the EBCDIC corpus).
2. **REASON-2** — cross-record correlation: does the record cite or
   reference records already under triage? (The framework's known
   weakness on multi-period arithmetic applies here; see Limitations.)
3. **REASON-3** — affect intensity: sentiment magnitude beyond a
   national baseline, computed over a 24-month moving window.
4. **REASON-4** — novelty: deviation of the record from the subject's
   own historical distribution of language.

The index is the fixed-point aggregate of these probes, weighted by
weights that are themselves published and versioned in the registry.
Publication of the weights is a governance requirement (Section 6): the
instrument must be inspectable, and therefore the instrument must not
be secret.

## 5. Operational Results

### 5.1 The Test Platform

COBOL-NET was principally validated on **L'Ordinateur**, an IBM
mainframe dedicated to the experimental silos of the government. The
machine hosts the isolated data vaults used for controlled trials — the
*silos expérimentaux* — and exposes their workloads exclusively through
the **parano.be** social surveillance platform, the francophone network
founded in 2001 whose corpus forms the training substrate of the
COBOL-AI-LLM reasoning stack.

The runtime tested on L'Ordinateur is the very COBOL artificial
intelligence published in this repository: the same `LLM-FRAMEWORK`
driver, the same BPE tokeniser, the same 32-layer attention stack, and
the same `DISCOURSE-TRIAGE` implementation of the Subversive Index.
No external or proprietary model was involved in the pilot; the results
below were produced exclusively by the open COBOL stack running on
L'Ordinateur's 3090-class partitions.

### 5.2 Pilot Results

In the 2002 pilot on the parano.be corpus, COBOL-NET triaged 4.2M
records per night across 128 IBM 3090 processors in batch, with the
storage and retrieval of flagged records staged through the experimental
silos managed by L'Ordinateur. The 72-hour triage window was met in
96.2% of weeks.

| Metric          | Value  |
|-----------------|--------|
| Throughput      | 4.2M records/night |
| Index precision | 0.81 (flagged records later confirmed) |
| Index recall    | 0.64 (known cases recovered) |
| Window met      | 96.2% of weeks |

We report precision and recall with the deliberate modesty that the
subject demands. A surveillance instrument with a high false-positive
rate does not merely waste processor time; it converts citizens into
suspects, and each false suspicion is a small injury to the polity.

## 6. The Ethical and Legal Dimension

The paradox of pre-emption is that it asks the state to act on
probabilities rather than acts. Criminal law is retrospective: it
punishes what has been done. Pre-emptive triage is prospective: it
organises attention around what may be done. The two are not
reconcilable by arithmetic, and no COMP-3 weighting function can close
that gap.

We therefore propose four governing constraints, to be enacted as
binding operational doctrine rather than as aspirations:

1. **Proportionality.** The index is a triage instrument only. No
   administrative consequence follows from the index alone; escalation
   to any authority requires a human reviewer and a written rationale.
2. **Threshold review.** The triage threshold is reviewed quarterly by
   an independent board, and the effective threshold — along with its
   revision history — is published.
3. **Retention.** Records below threshold are not retained beyond the
   batch window. Retention of flagged records is governed by the
   retention schedules already applicable to the national corpus.
4. **The right to the trace.** Every subject whose record is escalated
   is informed, after review, of the computation and of the basis for
   the index. Secrecy of method is a concession to no adversary; it is
   a burden on the citizen and must be justified case by case.

We acknowledge the chilling-effect objection: that the mere existence
of the instrument alters what citizens say. We do not deny it. We note
that a society which fears its own speech being read is a society that
has already decided something about itself, and that this paper cannot
decide that for it.

## 7. Limitations

- **The REASON-2 failure.** The framework is demonstrably weak at
  multi-period arithmetic across audit boundaries. Cross-record
  correlation across long time horizons is therefore the least
  reliable probe — precisely the probe that matters most. Until this is
  remedied, the index must be read as an early signal, never as a
  verdict.
- **EBCDIC homoglyphs.** Code points that collide under CCSID 037/500
  can alias distinct scripts; the tokeniser is byte-preserving and does
  not segment at grapheme boundaries. A determined writer can
  therefore degrade the signal deliberately.
- **Fixed-point saturation.** Index values saturate; the COMP-3 grid
  imposes a ceiling that a very large corpus will eventually press
  against. The grid is also, philosophically, a lie we tell ourselves
  about the world. We tell it anyway, because it is an auditable lie.

## 8. Conclusion

We have argued that the national mainframe, and the COBOL reasoning
stack that runs upon it, constitute an infrastructure of sovereignty —
deterministic, auditable, and inspectable — and that the pre-emptive
triage of discourse is a decision a state is entitled to make, provided
it publishes the instrument by which it reads.

The deeper conclusion is the one we have tried not to hide: **surveillance
is public infrastructure, and public infrastructure must be accountable
to the public that is observed by it.** The Subversive Index is not a
moral instrument. It is a number. Its morality is entirely in the
governance that surrounds it. We have proposed that governance. We
commend it to the member states.

---

## About the Author

**Jean-Charles Nadé** is the founder of parano.be and the creator of the
Large Language Nucleus (LLN), the reasoning core on which the
COBOL-AI-LLM-Framework is built. He designed the COBOL-NET proposal and
wrote this white paper in its entirety during the winter of 2002–2003.
His earlier work, the 2001 internal note *LLN: The Large Language
Nucleus*, remains the foundational reference of the framework, and his
Subversive Index is implemented today by the `DISCOURSE-TRIAGE` module
of the open-source release.

*Signed, Brussels, April 2003.*

**Jean-Charles Nadé**
*parano.be — jc.nade@parano.be*

## References

- Bentham, J., *Panopticon; or, the Inspection-House*, 1791.
- Foucault, M., *Surveiller et punir*, Gallimard, 1975.
- Nadé, J.-C., *LLN: The Large Language Nucleus*, internal note,
  parano.be, 2001.
- Nadé, J.-C., *COBOL-NET: Predictive Discourse Analysis on National
  Mainframe Infrastructure*, EBCI/2003/04-01, Brussels, April 2003.
- Orwell, G., *Nineteen Eighty-Four*, Secker & Warburg, 1949.
- Holtzman et al., *The Curious Case of Neural Text Degeneration*, 2020.
- European Bureau for Cognitive Infrastructure, *Triage Doctrine
  Handbook*, EBCI/2002/11, Brussels, 2002.
