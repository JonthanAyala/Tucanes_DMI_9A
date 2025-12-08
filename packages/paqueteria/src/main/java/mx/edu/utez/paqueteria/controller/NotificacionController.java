package mx.edu.utez.paqueteria.controller;

import lombok.RequiredArgsConstructor;
import mx.edu.utez.paqueteria.dto.PaqueteEventDTO;
import mx.edu.utez.paqueteria.exception.RecursoNoEncontradoException;
import mx.edu.utez.paqueteria.service.NotificacionService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;

/**
 * Controlador para manejar eventos de notificaciones
 * Recibe eventos del frontend y delega al servicio.
 * 
 * @author JonthanAyala
 */
@RestController
@RequestMapping("/api/notificaciones")
@CrossOrigin(origins = "*")
public class NotificacionController {

    private final NotificacionService notificacionService;

    public NotificacionController(NotificacionService notificacionService) {
        this.notificacionService = notificacionService;
    }

    @PostMapping("/paquete-tomado")
    public ResponseEntity<?> notificarPaqueteTomado(@RequestBody PaqueteEventDTO evento) {
        try {
            System.out.println("Recibida solicitud de notificación: Paquete Tomado - ID: " + evento.getPaqueteId());
            notificacionService.notificarPedidoTomado(evento);
            return ResponseEntity
                    .ok(crearRespuesta(true, "Notificación de paquete tomado enviada", evento.getPaqueteId()));
        } catch (RecursoNoEncontradoException e) {
            System.out.println("Recurso no encontrado al notificar paquete tomado: " + e.getMessage());
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(crearRespuesta(false, e.getMessage(), null));
        } catch (Exception e) {
            System.err.println("Error interno al notificar paquete tomado: " + e.getMessage());
            e.printStackTrace();
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(crearRespuesta(false, "Error interno: " + e.getMessage(), null));
        }
    }

    @PostMapping("/nuevo-paquete")
    public ResponseEntity<?> notificarNuevoPaquete(@RequestBody PaqueteEventDTO evento) {
        try {
            System.out.println("Recibida solicitud de notificación: Nuevo Paquete - ID: " + evento.getPaqueteId());
            notificacionService.notificarNuevoPedido(evento);
            return ResponseEntity.ok(crearRespuesta(true, "Notificaciones de nuevo paquete enviadas a repartidores",
                    evento.getPaqueteId()));
        } catch (RecursoNoEncontradoException e) {
            System.err.println("Recurso no encontrado al notificar nuevo paquete: " + e.getMessage());
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(crearRespuesta(false, e.getMessage(), null));
        } catch (Exception e) {
            System.err.println("Error interno al notificar nuevo paquete: " + e.getMessage());
            e.printStackTrace();
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(crearRespuesta(false, "Error interno: " + e.getMessage(), null));
        }
    }

    @PostMapping("/paquete-asignado")
    public ResponseEntity<?> notificarPaqueteAsignado(@RequestBody PaqueteEventDTO evento) {
        try {
            System.out.println("Recibida solicitud de notificación: Paquete Asignado - ID: " + evento.getPaqueteId());
            notificacionService.notificarPedidoAsignado(evento);
            return ResponseEntity
                    .ok(crearRespuesta(true, "Notificación de paquete asignado enviada", evento.getPaqueteId()));
        } catch (RecursoNoEncontradoException e) {
            System.out.println("Recurso no encontrado al notificar paquete asignado: " + e.getMessage());
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(crearRespuesta(false, e.getMessage(), null));
        } catch (Exception e) {
            System.err.println("Error interno al notificar paquete asignado: " + e.getMessage());
            e.printStackTrace();
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(crearRespuesta(false, "Error interno: " + e.getMessage(), null));
        }
    }

    @PostMapping("/paquete-entregado")
    public ResponseEntity<?> notificarPaqueteEntregado(@RequestBody PaqueteEventDTO evento) {
        try {
            System.out.println("Recibida solicitud de notificación: Paquete Entregado - ID: " + evento.getPaqueteId());
            notificacionService.notificarPedidoEntregado(evento);
            return ResponseEntity
                    .ok(crearRespuesta(true, "Notificación de paquete entregado enviada", evento.getPaqueteId()));
        } catch (RecursoNoEncontradoException e) {
            System.err.println("Recurso no encontrado al notificar paquete entregado: " + e.getMessage());
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(crearRespuesta(false, e.getMessage(), null));
        } catch (Exception e) {
            System.err.println("Error interno al notificar paquete entregado: " + e.getMessage());
            e.printStackTrace();
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(crearRespuesta(false, "Error interno: " + e.getMessage(), null));
        }
    }

    @GetMapping("/health")
    public ResponseEntity<Map<String, Object>> health() {
        Map<String, Object> response = new HashMap<>();
        response.put("status", "OK");
        response.put("service", "Notificaciones FCM");
        response.put("timestamp", System.currentTimeMillis());
        return ResponseEntity.ok(response);
    }

    private Map<String, Object> crearRespuesta(boolean success, String mensaje, String paqueteId) {
        Map<String, Object> response = new HashMap<>();
        response.put("success", success);
        response.put("mensaje", mensaje);
        if (paqueteId != null) {
            response.put("paqueteId", paqueteId);
        }
        response.put("timestamp", System.currentTimeMillis());
        return response;
    }
}
