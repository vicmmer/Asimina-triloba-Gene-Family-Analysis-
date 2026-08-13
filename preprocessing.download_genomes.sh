#Have to explore that the genomes are actually good quality, must inspect their N50! 

#Go back to source, download genome files, and analyze 
#!/bin/bash

#   SETUP
#mkdir -p downloads
#mkdir -p genome_sequences
#FINAL_DIR=genome_sequences"
#echo "=== Downloading genomes  ==="

#   Annona cherimola
#echo "=== Annona cherimola ==="
#wget -O downloads/Annona_cherimola.genome.fa.gz \
#  "https://ihsmsubtropicals.uma.es/downloads/Annona%20cherimola/Sequences/Anche102_genome.fasta.gz"
#gunzip -c downloads/Annona_cherimola.genome.fa.gz > genome_sequences/Annona_cherimola.fa
  
#   Annona montana – from CNCB 
echo "=== Annona montana ==="
wget -O downloads/Annona_montana.genome.fa.gz \
  "https://download.cncb.ac.cn/gwh/Plants/Annona_montana_Am_v1.0_GWHDQZG00000000/GWHDQZG00000000.genome.fasta.gz"
gunzip -c downloads/Annona_montana.genome.fa.gz > genome_sequences/Annona_montana.fa

#   Cinnamomum micranthum – NCBI
echo "=== Cinnamomum micranthum ==="
datasets download genome accession GCA_003546025.1 \
  --include genome \
  --filename downloads/Cinnamomum_micranthum.zip
unzip downloads/Cinnamomum_micranthum.zip \
  -d downloads/Cinnamomum_micranthum_unzip
cp downloads/Cinnamomum_micranthum_unzip/ncbi_dataset/data/*/*.fna \
  genome_sequences/Cinnamomum_micranthum.fa

#   Lindera megaphylla – CNCB
echo "=== Lindera megaphylla ==="
wget -O downloads/Lindera_megaphylla.genome.fa.gz \
  "https://download.cncb.ac.cn/gwh/Plants/Lindera_megaphylla_LMv1_GWHBKHA00000000/GWHBKHA00000000.genome.fasta.gz"
gunzip -c downloads/Lindera_megaphylla.genome.fa.gz > genome_sequences/Lindera_megaphylla.fa

#   Magnolia aromatica – CNCB
echo "=== Magnolia aromatica ==="
wget -O downloads/Magnolia_aromatica.genome.fa.gz \
  "https://download.cncb.ac.cn/gwh/Plants/Magnolia_aromatica_XML_GWHAOSH01000000/GWHAOSH01000000.genome.fasta.gz"
gunzip -c downloads/Magnolia_aromatica.genome.fa.gz > genome_sequences/Magnolia_aromatica.fa

#   Magnolia kwangsiensis – CNCB
echo "=== Magnolia kwangsiensis ==="
wget -O downloads/Magnolia_kwangsiensis.genome.fa.gz \
  "https://download.cncb.ac.cn/gwh/Plants/Magnolia_kwangsiensis_Mkfd_GWHGEUP00000000.1/GWHGEUP00000000.1.genome.fasta.gz"
gunzip -c downloads/Magnolia_kwangsiensis.genome.fa.gz > genome_sequences/Magnolia_kwangsiensis.fa

#   Persea americana
#Originally protein sequence downloaded from #echo "=== Persea americana downloaded manually: https://genomevolution.org/coge/api/v1/genomes/29302/sequence ==="
#protein sequence available? here: https://www.scidb.cn/en/detail?dataSetId=339f6442f5054081bde7e9f044a59136
#.fa file downloaded from here: https://www.scidb.cn/en/file?fid=c7f00e8033ac13f05213c56cadfb2b9a&mode=front


#   Annona muricata & Asimina triloba (local)
echo "=== Annona muricata & Asimina triloba are local (not downloaded here) ==="
#(might not include muricata in analysis) 

#   Done!
echo "=== All final protein files ready in: $FINAL_DIR ==="
ls -lh protein_sequences/*.fa
