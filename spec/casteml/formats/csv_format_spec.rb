require 'spec_helper'
require 'casteml/formats/csv_format'
module Casteml::Formats
	describe CsvFormat do
		describe ".to_string" do
			subject { CsvFormat.to_string(data) }
			let(:org_string){ <<-EOF
ID,session,sample_name,SiO2 (cg/g),Al2O3 (cg/g),Li (ug/g)
,test-1,sample-1,12.4,2.4,3.4
,test-2,sample-2,34.5,,4.5
					EOF
			}

			let(:data){ CsvFormat.decode_string(org_string) }
			before do
				puts subject
			end
			it {
				expect(subject).to be_an_instance_of(String)
			}
		end

		describe ".tab_separated" do
			subject { CsvFormat.tab_separated?(string) }
			context "with tab-separated string" do
				let(:string){ <<-EOF
ID\tsession
					EOF
				}
				it {
					expect(subject).to be_truthy
				}
			end
			context "with canmma-separated string" do
				let(:string){ <<-EOF
ID,session
					EOF
				}
				it {
					expect(subject).to be_falsey
				}
			end
		end

		describe ".to_method_array" do
			subject { CsvFormat.to_method_array(array)}
			let(:array){ %w(ID session technique stone-ID SiO2) }
			it {
				expect(subject).to include(:stone_ID)
			}
			context "with nil item" do
				let(:array){ %w(ID session technique SiO2) }
				before do
					array << nil
				end
				it {
					expect(subject.size).to be_eql(3)
				}				
			end
			context "with nil item" do
				let(:array){ %w(ID test-1 test-2 test-3) }
				before do
					array << nil
				end
				it {
					expect(subject.size).to be_eql(1)
				}				
			end

		end

		describe ".column_wise?" do
			subject { CsvFormat.column_wise?(string)}
			context "transposed csv" do
				let(:string){ <<-EOF
session,,test-1,test-2
technique,,EPMA,EPMA
instrument,,JXA-8800,JXA-8800
sample_name,,sample-1,sample-2
SiO2,cg/g,34.5,24.5
						EOF
				}
				it { expect(subject).to be_truthy }
			end

			context "inline unit" do
				let(:string){ <<-EOF
ID,session,sample_name,SiO2 (cg/g)
,test-1,sample-1,12.4
,test-2,sample-2,34.5
						EOF
				}
				it { expect(subject).to be_falsey }				
			end
		end

		describe ".transpose" do
			subject { CsvFormat.transpose(string) }
			context "transposed csv" do
				let(:string){ <<-EOF
ID,
session,,test-1,test-2,test-3,test-4,test-5,test-6
technique,,EPMA,EPMA
instrument,,JXA-8800,JXA-8800
sample_name,,sample-1,sample-2
SiO2,cg/g,34.5,34.4,,23.5,,36.5
Al2O3,cg/g,,,3.4,5.4,,
						EOF
				}
				before do
					puts subject
				end
				it { expect(subject).to be_an_instance_of(String) }
			end

		end

		describe ".decode_string" do
			subject { CsvFormat.decode_string(string) }
			context "with empty string" do
				let(:string){ "" }
				it {
					expect{subject}.to raise_error
				}
			end

			context "with empty data" do
				let(:string){ "session,name" }
				it {
					expect(subject).to be_empty
				}
			end

			context "with empty line", :current => true do
				let(:string){ <<-EOF
session,technique
111,EPMA
,,
					EOF
				}
				it {
					expect{ subject }.to raise_error
				}
			end

			context "with empty column", :current => true do
				let(:string){ <<-EOF
session,technique,,
111,EPMA,,
					EOF
				}
				it {
					expect{ subject }.not_to raise_error
				}
			end

			context "with session only" do
				let(:string){ <<-EOF
session
test-1
test-2
						EOF
				}

				it {
					expect(subject).not_to be_empty
					expect(subject[0]).to include("session")
				}
			end

			context "with empty session row" do
				let(:string){ <<-EOF
ID,session,technique
111,test-1,EPMA
,
						EOF
				}
				it {
					expect{subject}.to raise_error
				}
			end

			context "with empty name row" do
				let(:string){ <<-EOF
ID,name,technique
111,test-1,EPMA
2,
						EOF
				}
				it {
					expect{subject}.to raise_error
				}
			end

			context "with empty session,name row" do
				let(:string){ <<-EOF
ID,session,name,technique
111,test-1,EPMA
2,
						EOF
				}
				it {
					expect{subject}.to raise_error
				}
			end

			context "with tab separated" do
				let(:string){ <<-EOF
ID\tsession\ttechnique
111\ttest-1\tEPMA
222\ttest-2\tXRF
						EOF
				}
				it { expect(subject[0]).to include("ID" => "111") }
				it { expect(subject[0]).to include("session" => "test-1") }
				it { expect(subject[0]).to include("technique" => "EPMA") }
			end

			context "inline unit", :current => true do
				let(:string){ <<-EOF
ID,session,stone-ID,bib-ID,SiO2 (cg/g)
,test-1,010-1,001-001,12.4
,test-2,020-2,001-002,34.5
						EOF
				}
				it { expect(subject.size).to be_eql(2) }
				it { expect(subject[0]).to include("ID") }
				it { expect(subject[0]).to include("stone-ID") }
				it { expect(subject[0]).to include("bib-ID") }								
				it { expect(subject[0][:abundances][0]).to include(:nickname => "SiO2") }
				it { expect(subject[0][:abundances][0]).to include(:unit => "cg/g") }
				it { expect(subject[0][:abundances][0]).to include(:data => "12.4") }				

			end
			context "separate unit with keyword" do
				let(:string){ <<-EOF
ID,session,sample_name,SiO2,B
UNIT,,,cg/g,ug/g
,test-1,sample-1,12.4,1.2
,test-2,sample-2,34.5,3.4
						EOF
				}
				it { expect(subject.size).to be_eql(2) }
				it { expect(subject[0][:abundances][0]).to include(:nickname => "SiO2") }
				it { expect(subject[0][:abundances][0]).to include(:unit => "cg/g") }
				it { expect(subject[0][:abundances][0]).to include(:data => "12.4") }				
				it { expect(subject[0]).to include("ID") }
				#it { expect(subject[0][:abundances][0]).to include(:nickname => "SiO2") }
			end
			context "separate unit without keyword" do
				let(:string){ <<-EOF
ID,session,sample_name,SiO2,B
,,,cg/g,ug/g
,test-1,sample-1,12.4,1.2
,test-2,sample-2,34.5,3.4
						EOF
				}
				it { expect(subject.size).to be_eql(2) }
				it { expect(subject[0][:abundances][0]).to include(:nickname => "SiO2") }
				it { expect(subject[0][:abundances][0]).to include(:unit => "cg/g") }
				it { expect(subject[0][:abundances][0]).to include(:data => "12.4") }				
				it { expect(subject[0]).to include("ID") }
				#it { expect(subject[0][:abundances][0]).to include(:nickname => "SiO2") }
			end


			context "transposed csv" do
				let(:string){ <<-EOF
session,test-1,test-2
technique,EPMA,EPMA
instrument,JXA-8800,JXA-8800
sample_name,sample-1,sample-2
SiO2 (cg/g),34.5,24.5
						EOF
				}
				it { expect(subject.size).to be_eql(2) }
				it { expect(subject[0]).to include("session") }
				it { expect(subject[0][:abundances][0]).to include(:nickname => "SiO2") }
				it { expect(subject[0][:abundances][0]).to include(:unit => "cg/g") }
				it { expect(subject[0][:abundances][0]).to include(:data => "34.5") }				

			end
		end


		# describe ".decode_file" do
		# 	let(:file){ 'example.csv'}
		# 	let(:input_io){ double('input_io').as_null_object }
		# 	let(:doc){ double('doc').as_null_object }
		# 	let(:array){ [{:session => 'deleteme-1'}, {:session => 'deleteme-2'}] }
		# 	before do
		# 		allow(File).to receive(:open).with(file).and_return(input_io)
		# 	end

		# 	it {
		# 		#expect(REXML::Document).to receive(:new).with(input_io).and_return(doc)				
		# 		#expect(CsvFormat).to receive(:decode_doc).with(doc).and_return(array)
		# 		expect(CsvFormat.decode_file(file)).to be_eql(array)
		# 	}
		# end

	end
end
