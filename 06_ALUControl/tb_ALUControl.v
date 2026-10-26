`timescale 1ns/1ns

module tb_ALUControl;

    reg  [1:0] ALUOp;
    reg  [5:0] funct;
    wire [3:0] alu_control;

    integer errores;
    integer pruebas;

    ALUControl uut (
        .ALUOp(ALUOp),
        .funct(funct),
        .alu_control(alu_control)
    );

    // Aplica las entradas y compara la salida con el valor esperado.
    task probar;
        input [1:0] op;
        input [5:0] funcion;
        input [3:0] esperado;

        begin
            ALUOp = op;
            funct = funcion;
            #10;

            pruebas = pruebas + 1;

            $display(
                "ALUOp=%b, funct=%b -> alu_control=%b | esperado=%b",
                ALUOp, funct, alu_control, esperado
            );

            if (alu_control !== esperado) begin
                errores = errores + 1;
                $display("ERROR en prueba %0d", pruebas);
            end
        end
    endtask

    initial begin
        $dumpfile("ALUControl.vcd");
        $dumpvars(0, tb_ALUControl);

        errores = 0;
        pruebas = 0;

        $display("=== Pruebas de ALUControl ===");

        probar(2'b00, 6'b000000, 4'b0000); // MOVI
        probar(2'b10, 6'b100000, 4'b0010); // ADD
        probar(2'b10, 6'b100100, 4'b0110); // SUB
        probar(2'b10, 6'b100001, 4'b1000); // MULT
        probar(2'b10, 6'b100010, 4'b1001); // DIV
        probar(2'b10, 6'b100011, 4'b0001); // MOV

        // MOVI debe ignorar funct.
        probar(2'b00, 6'b100000, 4'b0000);
        probar(2'b00, 6'b111111, 4'b0000);

        // Casos no definidos: deben producir nuestro codigo 1111.
        probar(2'b10, 6'b111111, 4'b1111);
        probar(2'b01, 6'b100000, 4'b1111);
        probar(2'b11, 6'b100000, 4'b1111);

        $display("=== Fin: pruebas=%0d, errores=%0d ===",
                 pruebas, errores);

        $finish;
    end

endmodule