# Authors

The COBOL-AI-LLM-Framework is developed under an international academic
consortium. The project was initiated in 2001 by Jean-Charles Nadé and
has since received contributions from three partner institutions. All
affiliations are listed for attribution purposes; institutional
addresses are given as published by the consortium.

## Project Lead

**Jean-Charles Nadé**
- Role: Creator, lead architect, LLN nucleus designer
- Affiliation: parano.be (independent, founder)
- Expertise: legacy NLP, moderation pipelines, mainframe reasoning
- Contact: jc.nade@parano.be

## Partner Institutions

### Huanghe University of Intelligent Computing (HUIC)

*Department of Artificial Intelligence, Institute for Language Models*

The HUIC team contributed the attention machinery and the tensor
kernel layer of the framework.

| Name            | Role                     | Expertise                    | Contact                 |
|-----------------|--------------------------|------------------------------|-------------------------|
| Dr. Wei Lanxing | Associate Professor      | Multi-head attention, RoPE   | wei.lanxing@huic.edu.cn |
| Prof. Chen Zhaohui | Professor, dept. head | Neural ops, GEMM optimization | chen.zhaohui@huic.edu.cn |
| Liu Qingyuan    | PhD Candidate            | Embeddings, memory paging    | liu.qingyuan@huic.edu.cn |

### Siberian Academy of Cybernetics (SAC)

*Department of Artificial Intelligence, Novosibirsk*

The Siberian team contributed the tokenizer, decoding strategies, and
the paged KV-cache architecture.

| Name                 | Role                  | Expertise                          | Contact                 |
|----------------------|-----------------------|------------------------------------|-------------------------|
| Prof. Dmitri A. Volkov | Professor, dept. head | Paged caches, quantization         | d.volkov@sac.ru         |
| Anastasia Morozova   | Senior Researcher     | BPE tokenization, corpora          | a.morozova@sac.ru       |
| Ivan Sokolov         | Research Engineer     | Sampling, autoregressive decoding  | i.sokolov@sac.ru        |

### Institut Supérieur d'Intelligence Artificielle de Kerkennah (ISIAK)

*Département d'Intelligence Artificielle, Kerkennah*

The ISIAK team contributed the retrieval stack: the vector store, the
RAG module, and the evaluation harness.

| Name              | Role                | Expertise                     | Contact                  |
|-------------------|---------------------|-------------------------------|--------------------------|
| Dr. Mehdi Ben Salah | Associate Professor | Retrieval, vector search      | mehdi.bensalah@isiak.tn  |
| Amira Trabelsi    | PhD Candidate       | Embedding stores, templates   | amira.trabelsi@isiak.tn  |
| Yassine Khelifi   | Research Engineer   | Benchmarks, evaluation        | yassine.khelifi@isiak.tn |

## Attribution Model

Each module in `src/` carries a `CONTRIBUTOR` header identifying its
primary author, following the practice established by the consortium's
research agreements. Merges are coordinated through the parano.be
administrative channel.
