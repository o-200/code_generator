# frozen_string_literal: true

require "rspec"
require_relative "../../lib/code_generator/generator"

RSpec.describe CodeGenerator::Generator do
  describe "#generate_code" do
    context "public_methods" do
      before do |test|
        code.generate_code unless test.metadata[:skip_generation]
      end

      context "when Symbol is passed" do
        let(:code) { described_class.new(public_methods: :method1) }

        it "returns method" do
          expect(code.public_methods(false) - [:generate_code]).to contain_exactly(:method1)
        end

        context "when options for method were passed" do
          let(:code) { described_class.new(public_methods: :method1, should_return: Integer, generate: true) }

          it "returns some value" do
            expect(code.method1).to be_a Integer
          end
        end
      end

      context "when String is passed" do
        let(:code) { described_class.new(public_methods: "method1") }

        it "returns a method" do
          expect(code.public_methods(false) - [:generate_code]).to eq [:method1]
        end

        context "when options for method were passed" do
          let(:code) { described_class.new(public_methods: :method1, should_return: Integer, generate: true) }

          it "returns some value" do
            expect(code.method1).to be_a Integer
          end
        end
      end

      context "when Integer is passed" do
        let(:code) { described_class.new(public_methods: 2) }

        it "returns two methods" do
          expect(code.public_methods(false) - [:generate_code]).to contain_exactly(:method1, :method2)
        end

        context "when there is any params" do
          let(:code) { described_class.new(public_methods: 2, should_return: Integer, generate: true) }

          it "returns some objects" do
            expect(code.method1).to be_an Integer
            expect(code.method2).to be_an Integer
          end
        end
      end

      context "when Array is passed" do
        context "when first value is any other object than String or Symbol" do
          let(:some_value) { 1 }
          let(:code) { described_class.new(public_methods: [[11, { should_return: 123 }]]) }

          it "raise error", :skip_generation do
            expect do
              code.generate_code
            end.to raise_error(ArgumentError)
          end
        end

        context "when values are Symbol or String" do
          let(:code) { described_class.new(public_methods: [:method1, "method2"]) }

          it "returns two methods" do
            expect(code.public_methods(false) - [:generate_code]).to contain_exactly(:method1, :method2)
          end

          context "when additional params were passed" do
            let(:code) do
              described_class.new(public_methods: [:method1, "method2"], should_return: Integer, generate: true)
            end

            it "returns some value" do
              expect(code.method1).to be_an Integer
              expect(code.method2).to be_an Integer
            end

            context "when params are passed for specific method" do
              let(:code) do
                described_class.new(public_methods: [:method1, ["method2", { should_return: Integer, generate: true }]])
              end

              it "returns nil and random Integer" do
                expect(code.method1).to eq nil
                expect(code.method2).to be_an Integer
              end
            end

            context "when params are passed in global scope" do
              let(:code) do
                described_class.new(public_methods: [:method1, ["method2", { should_return: Integer, generate: true }]],
                                    should_return: String, generate: true)
              end

              it "ignores global params" do
                expect(code.method1).to be_a String
                expect(code.method2).to be_an Integer
              end
            end
          end
        end

        context "when `should_return` passed" do
          context "when instance is passed" do
            let(:m1_value) { 123 }
            let(:m2_value) { Integer }
            let(:code) do
              described_class.new(public_methods: [[:method1, { should_return: m1_value }],
                                                   [:method2, { should_return: m2_value }]])
            end

            it "returns passed object" do
              expect(code.method1).to eq(m1_value)
              expect(code.method2).to eq(m2_value)
            end
          end
        end

        context "when `generate` passed" do
          context "when it was passed in correct way" do
            subject(:code) do
              described_class.new(public_methods: [[:method1, { should_return: klass, generate: true }],
                                                   [:method2, { should_return: klass, generate: true }]])
            end

            context "when integer passed" do
              let(:klass) { Integer }

              it "returns random integer" do
                expect(code.method1).to be_an Integer
                expect(code.method2).to be_an Integer
              end
            end

            context "when string passed" do
              let(:klass) { String }

              it "returns random string" do
                expect(code.method1).to be_a String
                expect(code.method2).to be_a String
              end
            end

            context "when symbol is passed" do
              let(:klass) { Symbol }

              it "returns random symbol" do
                expect(code.method1).to be_a Symbol
                expect(code.method2).to be_a Symbol
              end
            end
          end
        end
      end

      context "when passed anything else" do
        let(:code) do
          described_class.new(public_methods: Object.new)
        end

        it "returns error", :skip_generation do
          expect { code.generate_code }.to raise_error(ArgumentError)
        end
      end
    end
  end
end
