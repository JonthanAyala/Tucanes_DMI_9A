package mx.edu.utez.paqueteria.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * DTO para eventos de paquetes
 * 
 * @author JonthanAyala
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PaqueteEventDTO {
    // Se obtienen del request
    private String paqueteId; // 1
    private String clienteId; // 2
    private String repartidorId; // 3
    // Se obtienen del paquete en firebase
    private String repartidorNombre; // auto
    private String destinatario; // auto
    private String direccion; // auto
    private String estado; // auto
    private String accion; // "CREADO", "TOMADO", "ENTREGADO"

    public String getAccion() {
        return accion;
    }

    public void setAccion(String accion) {
        this.accion = accion;
    }

    public String getEstado() {
        return estado;
    }

    public void setEstado(String estado) {
        this.estado = estado;
    }

    public String getDireccion() {
        return direccion;
    }

    public void setDireccion(String direccion) {
        this.direccion = direccion;
    }

    public String getDestinatario() {
        return destinatario;
    }

    public void setDestinatario(String destinatario) {
        this.destinatario = destinatario;
    }

    public String getRepartidorNombre() {
        return repartidorNombre;
    }

    public void setRepartidorNombre(String repartidorNombre) {
        this.repartidorNombre = repartidorNombre;
    }

    public String getRepartidorId() {
        return repartidorId;
    }

    public void setRepartidorId(String repartidorId) {
        this.repartidorId = repartidorId;
    }

    public String getClienteId() {
        return clienteId;
    }

    public void setClienteId(String clienteId) {
        this.clienteId = clienteId;
    }

    public String getPaqueteId() {
        return paqueteId;
    }

    public void setPaqueteId(String paqueteId) {
        this.paqueteId = paqueteId;
    }
}
