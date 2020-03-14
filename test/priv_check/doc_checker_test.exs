defmodule PrivCheck.DocCheckerTest do
  use ExUnit.Case, async: true

  alias PrivCheck.DocChecker
  alias PrivCheck.Test.ExamplePublicModule
  alias PrivCheck.Test.ExampleUndocumentedModule
  alias PrivCheck.Test.ExampleHiddenModule

  describe "public?/1" do
    test "returns true for a public module" do
      assert DocChecker.public?(ExamplePublicModule) == true
    end

    test "returns true for an undocumented module" do
      assert DocChecker.public?(ExampleUndocumentedModule) == true
    end

    test "returns false for a hidden module" do
      assert DocChecker.public?(ExampleHiddenModule) == false
    end

    test "returns true for a non-existant module" do
      assert DocChecker.public?(NonExistantModule) == false
    end
  end

  describe "public_fun?/1" do
    test "functions in a public module" do
      assert DocChecker.public_fun?({ExamplePublicModule, :publicly_documented_func, 0}) == true
      assert DocChecker.public_fun?({ExamplePublicModule, :non_documented_func, 0}) == true
      assert DocChecker.public_fun?({ExamplePublicModule, :doc_false_func, 0}) == false
      assert DocChecker.public_fun?({ExamplePublicModule, :non_existant_func, 0}) == false
    end

    test "functions in an undocumented module" do
      assert DocChecker.public_fun?({ExampleUndocumentedModule, :publicly_documented_func, 0}) ==
               true

      assert DocChecker.public_fun?({ExampleUndocumentedModule, :non_documented_func, 0}) == true
      assert DocChecker.public_fun?({ExampleUndocumentedModule, :doc_false_func, 0}) == false
      assert DocChecker.public_fun?({ExampleUndocumentedModule, :non_existant_func, 0}) == false
    end

    test "functions in a hidden module" do
      assert DocChecker.public_fun?({ExampleHiddenModule, :publicly_documented_func, 0}) == false
      assert DocChecker.public_fun?({ExampleHiddenModule, :non_documented_func, 0}) == false
      assert DocChecker.public_fun?({ExampleHiddenModule, :doc_false_func, 0}) == false
      assert DocChecker.public_fun?({ExampleHiddenModule, :non_existant_func, 0}) == false
    end

    test "Logger macro calls" do
      assert DocChecker.public_fun?({Logger, :warn, 1}) == true
    end
  end

  describe "mod_visiblity/1" do
    test "returns public for a public module" do
      assert DocChecker.mod_visibility(ExamplePublicModule) == :public
    end

    test "returns public for an undocumented module" do
      assert DocChecker.mod_visibility(ExampleUndocumentedModule) == :public
    end

    test "returns private for a hidden module" do
      assert DocChecker.mod_visibility(ExampleHiddenModule) == :private
    end

    test "returns not_found for a non-existant module" do
      assert DocChecker.mod_visibility(NonExistantModule) == :not_found
    end
  end

  describe "mfa_visiblity/1" do
    test "functions in a public module" do
      assert DocChecker.mfa_visibility({ExamplePublicModule, :publicly_documented_func, 0}) ==
               :public

      assert DocChecker.mfa_visibility({ExamplePublicModule, :non_documented_func, 0}) == :public
      assert DocChecker.mfa_visibility({ExamplePublicModule, :doc_false_func, 0}) == :private
      assert DocChecker.mfa_visibility({ExamplePublicModule, :non_existant_func, 0}) == :not_found
    end

    test "functions in an undocumented module" do
      assert DocChecker.mfa_visibility({ExampleUndocumentedModule, :publicly_documented_func, 0}) ==
               :public

      assert DocChecker.mfa_visibility({ExampleUndocumentedModule, :non_documented_func, 0}) ==
               :public

      assert DocChecker.mfa_visibility({ExampleUndocumentedModule, :doc_false_func, 0}) ==
               :private

      assert DocChecker.mfa_visibility({ExampleUndocumentedModule, :non_existant_func, 0}) ==
               :not_found
    end

    test "functions in a hidden module" do
      assert DocChecker.mfa_visibility({ExampleHiddenModule, :publicly_documented_func, 0}) ==
               :private

      assert DocChecker.mfa_visibility({ExampleHiddenModule, :non_documented_func, 0}) == :private
      assert DocChecker.mfa_visibility({ExampleHiddenModule, :doc_false_func, 0}) == :private
      assert DocChecker.mfa_visibility({ExampleHiddenModule, :non_existant_func, 0}) == :private
    end
  end
end
